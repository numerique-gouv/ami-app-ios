//
//  WebView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
import Foundation
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    init(_ url: URL) {
        self.url = url
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Add message handler for JavaScript bridge
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "NativeBridge")

        // Inject JavaScript bridge to match Android interface
        // This creates window.NativeBridge.onEvent() that wraps the iOS messaging
        let bridgeScript = WKUserScript(
            source: """
            window.NativeBridge = {
                onEvent: function(eventName, data) {
                    window.webkit.messageHandlers.NativeBridge.postMessage({
                        event: eventName,
                        data: data
                    });
                }
            };
            console.log('NativeBridge initialized for iOS');
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(bridgeScript)
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))

        // Store webView reference in coordinator
        context.coordinator.webView = webView

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: WebView
        weak var webView: WKWebView?
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

        deinit {
            NotificationCenter.default.removeObserver(self)
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
            guard let webView = webView, isUserLoggedIn else {
                print("WebView: Cannot register device - user not logged in or webView not ready")
                return
            }

            // Get FCM token from UserDefaults
            guard let fcmToken = UserDefaults.standard.string(forKey: "fcmToken") else {
                print("WebView: ⚠️ FCM token not yet available - not registering")
                return
            }

            let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            let deviceModel = UIDevice.current.model
            let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
            let baseUrl = Config.shared.BASE_URL

            print("WebView: ✅ Registering device - token=\(fcmToken) deviceId=\(deviceId) model=\(deviceModel) platform=ios app_version=\(appVersion)")

            let script = """
            (function() {
                console.log('Registering device...');

                fetch('\(baseUrl)/api/v1/users/registrations', {
                    method: 'POST',
                    credentials: 'include',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({
                        subscription: {
                            fcm_token: "\(fcmToken)",
                            device_id: "\(deviceId)",
                            platform: "ios",
                            app_version: "\(appVersion)",
                            model: "\(deviceModel)"
                        }
                    })
                })
                .then(response => {
                    console.log('Registration response status:', response.status);
                    return response.json();
                })
                .then(data => {
                    console.log('✅ Device registered successfully:', data);
                })
                .catch(error => {
                    console.error('❌ Registration failed:', error);
                });
            })();
            """

            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("WebView: JavaScript execution failed: \(error)")
                }
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
    }
}
