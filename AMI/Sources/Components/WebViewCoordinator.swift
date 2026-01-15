//
//  WebViewCoordinator.swift
//  AMI
//
//  Created by Aline Bonnet on 22/12/2025.
//

import Foundation
import SwiftUI
@preconcurrency import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: WebView
    private var progressObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    private var isLoadingBinding: Binding<Bool>
    private var loadingProgressBinding: Binding<Double>
    private var isOnContactPageBinding: Binding<Bool>
    var isUserLoggedIn = false

    init(_ parent: WebView, isLoading: Binding<Bool>, loadingProgress: Binding<Double>, isOnContactPage: Binding<Bool>) {
        self.parent = parent
        isLoadingBinding = isLoading
        loadingProgressBinding = loadingProgress
        isOnContactPageBinding = isOnContactPage
        super.init()

        // Listen for FCM token refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFCMTokenRefresh(_:)),
            name: .fcmTokenRefreshed,
            object: nil
        )
    }

    func triggerDeviceRegistration() {
        guard isUserLoggedIn else {
            print("WebView: Cannot register device - user not logged in or webView not ready")
            return
        }

        // Get FCM token from UserDefaults
        guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
            print("WebView: ⚠️ FCM token not yet available - not registering")
            return
        }

        let webView = WebViewManager.shared.webView

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceModel = UIDevice.current.model
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let baseUrl = Config.shared.BASE_URL

        print("WebView: ✅ Registering device - fcmToken=\(fcmToken) deviceId=\(deviceId) model=\(deviceModel) platform=ios app_version=\(appVersion)")

        // Get the auth token cookie
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        cookieStore.getAllCookies { cookies in
            guard let authCookie = cookies.first(where: { $0.name == "token" }) else {
                print("WebView: ⚠️ No 'token' cookie found - cannot register device")
                return
            }

            // Remove the surrounding extraneous quotes.
            let token = authCookie.value.replacingOccurrences(of: "\"", with: "")

            // Make the API request
            Task {
                await self.registerDevice(
                    baseUrl: baseUrl,
                    token: token,
                    fcmToken: fcmToken,
                    deviceId: deviceId,
                    deviceModel: deviceModel,
                    appVersion: appVersion
                )
            }
        }
    }

    // TODO: pass a struct instead of 6 parameters.
    private func registerDevice(
        baseUrl: URL,
        token: String,
        fcmToken: String,
        deviceId: String,
        deviceModel: String,
        appVersion: String
    ) async {
        let url = baseUrl.appendingPathComponent("/api/v1/users/registrations")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "subscription": [
                "fcm_token": fcmToken,
                "device_id": deviceId,
                "platform": "ios",
                "app_version": appVersion,
                "model": deviceModel,
            ],
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("WebView: ✅ Device registered successfully")
                } else {
                    print("WebView: ⚠️ Device registration failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("WebView: ❌ Device registration error: \(error.localizedDescription)")
        }
    }

    @objc private func handleFCMTokenRefresh(_ notification: Notification) {
        if notification.userInfo?["token"] as? String == nil {
            print("WebView: FCM token refresh notification received but no token found")
            return
        }

        print("WebView: FCM token refreshed - new token received")

        // Only re-register if user is already logged in
        if isUserLoggedIn {
            print("WebView: User is logged in - triggering re-registration with new token")
            triggerDeviceRegistration()
        } else {
            print("WebView: User not logged in yet - will register with new token on login")
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Show loader immediately on link click (before page starts loading)
        Task { @MainActor in
            self.isLoadingBinding.wrappedValue = true
            self.loadingProgressBinding.wrappedValue = 0.0
        }

        guard let urlString = navigationAction.request.url?.absoluteString else { return }
        parent.isExternalProcess = !urlString.contains(Config.shared.BASE_URL.absoluteString)
        isOnContactPageBinding.wrappedValue = urlString.contains("/#/contact")

        print("WebView: 📍 Navigation to: \(urlString)")

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // In debug builds, accept self-signed certificates
        #if DEBUG
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        #endif

        // In release builds, use default handling (reject invalid certificates)
        completionHandler(.performDefaultHandling, nil)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "consoleLog": return ConsoleLog.printLog(message)
        case "NativeBridge": return NativeEvents.processMessage(message, coordinator: self)
        default:
            return
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            self.isLoadingBinding.wrappedValue = false
        }
    }

    func updateNotificationStatusInLocalStorage(webView: WKWebView) {
        print("WebView: updateNotificationStatusInLocalStorage called")
        Task {
            let isEnabled = await NotificationHelper.isNotificationEnabled()
            print("WebView: Notification status retrieved: \(isEnabled)")
            let script = "localStorage.setItem('notifications_enabled', '\(isEnabled)');"
            // TODO: check if `MainActor.run` is better than `Task { @MainActor`.
            await MainActor.run {
                webView.evaluateJavaScript(script) { _, error in
                    if let error {
                        print("WebView: Failed to set notifications_enabled in localStorage: \(error)")
                    } else {
                        print("WebView: Set notifications_enabled=\(isEnabled) in localStorage")
                    }
                }
            }
        }
    }

    func observeProgress(of wkWebView: WKWebView) {
        progressObservation = wkWebView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self else { return }
            Task { @MainActor in
                self.loadingProgressBinding.wrappedValue = webView.estimatedProgress
            }
        }

        urlObservation = wkWebView.observe(\.url, options: [.new]) { [weak self] webView, _ in
            guard let self else { return }
            print("WebView: URL changed to: \(webView.url?.absoluteString ?? "nil")")
            updateNotificationStatusInLocalStorage(webView: webView)
            guard let urlString = webView.url?.absoluteString else { return }
            Task { @MainActor in
                self.isOnContactPageBinding.wrappedValue = urlString.contains("/#/contact")
            }
        }
    }
}
