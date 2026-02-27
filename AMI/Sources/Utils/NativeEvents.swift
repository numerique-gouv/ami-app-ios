//import Foundation
//import WebKit
//
//enum NativeEvents {
//    static func attach(_ contentController: WKUserContentController, _ handler: WKScriptMessageHandler) {
//        // This creates window.NativeBridge.onEvent() that wraps the iOS messaging
//        let bridgeScript = """
//        window.NativeBridge = {
//            onEvent: function(eventName, data) {
//                window.webkit.messageHandlers.NativeBridge.postMessage({
//                    event: eventName,
//                    data: data
//                });
//            }
//        };
//        console.log('NativeBridge initialized for iOS');
//        """
//        let script = WKUserScript(source: bridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
//        contentController.addUserScript(script)
//        // By security, first remove any handler with the same name.
//        contentController.removeScriptMessageHandler(forName: "NativeBridge")
//        contentController.add(handler, name: "NativeBridge")
//    }
//
//    static func processMessage(_ message: WKScriptMessage, coordinator: WebViewOldCoordinator) {
//        // Parse the message from JavaScript (format: {event: string, data: any})
//        if let messageBody = message.body as? [String: Any],
//           let eventName = messageBody["event"] as? String {
//            let data = messageBody["data"]
//            print("WebView: Event received: \(eventName) - \(String(describing: data))")
//
//            switch eventName {
//            case "user_logged_in":
//                coordinator.isUserLoggedIn = true
//                // Trigger device registration when user logs in
//                coordinator.triggerDeviceRegistration()
//            case "notification_permission_requested":
//                NotificationHelperOld.requestPermission()
//            case "notification_permission_removed":
//                NotificationHelperOld.openSettings()
//                WebViewOldManager.shared.goHome()
//            default:
//                break
//            }
//        }
//    }
//}
