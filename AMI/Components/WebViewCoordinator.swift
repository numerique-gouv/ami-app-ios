import Foundation
@preconcurrency import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var webView: WKWebView?

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "consoleLog",
              let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let logMessage = body["message"] as? String else {
            return
        }

        let prefix = "[WebView Console]"
        switch level {
        case "error":
            print("\(prefix) ❌ ERROR: \(logMessage)")
        case "warn":
            print("\(prefix) ⚠️ WARN: \(logMessage)")
        case "info":
            print("\(prefix) ℹ️ INFO: \(logMessage)")
        case "debug":
            print("\(prefix) 🔍 DEBUG: \(logMessage)")
        default:
            print("\(prefix) 📝 LOG: \(logMessage)")
        }
    }
}
