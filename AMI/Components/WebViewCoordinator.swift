//
//  WebViewCoordinator.swift
//  AMI
//
//  Created by Aline Bonnet on 22/12/2025.
//

import Foundation
@preconcurrency import WebKit

class WebViewCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    var parent: WebView
    var isUserLoggedIn = false

    init(_ parent: WebView) {
        self.parent = parent
        super.init()

        // Listen for FCM token refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleFCMTokenRefresh(_:)),
            name: .fcmTokenRefreshed,
            object: nil
        )
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "NativeBridge" else { return }

        // Parse the message from JavaScript (format: {event: string, data: any})
        if let messageBody = message.body as? [String: Any],
           let eventName = messageBody["event"] as? String {

            let data = messageBody["data"]
            print("WebView: Event received: \(eventName) - \(String(describing: data))")

            if eventName == "user_logged_in" {
                isUserLoggedIn = true
                // Trigger device registration when user logs in
                triggerDeviceRegistration()
            }
        }
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

        guard let webView = parent.webViewRef else {
            print("WebView: ⚠️ WebView reference not ready - cannot register device")
            return
        }

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

    private func registerDevice(
        baseUrl: String,
        token: String,
        fcmToken: String,
        deviceId: String,
        deviceModel: String,
        appVersion: String
    ) async {
        guard let url = URL(string: "\(baseUrl)/api/v1/users/registrations") else {
            print("WebView: ❌ Invalid registration URL")
            return
        }

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
                "model": deviceModel
            ]
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
        guard let token = notification.userInfo?["token"] as? String else {
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
        guard let urlString = navigationAction.request.url?.absoluteString else { return }
        parent.isExternalProcess = !urlString.contains(Config.shared.BASE_URL)

        print("WebView: 📍 Navigation to: \(urlString)")

        decisionHandler(.allow)
    }
}
