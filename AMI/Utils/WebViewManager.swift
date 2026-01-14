import Foundation
import WebKit

class WebViewManager {
    static let shared = WebViewManager()

    weak var webView: WKWebView?

    private init() {}

    func goHome() {
        guard let webView = webView else {
            print("WebViewManager: No webView reference available")
            return
        }
        guard let url = URL(string: Config.shared.BASE_URL) else {
            print("WebViewManager: Invalid BASE_URL")
            return
        }
        print("WebViewManager: Navigating to home")
        webView.load(URLRequest(url: url))
    }
}
