import Foundation
import WebKit

class WebViewManager {
    static let shared = WebViewManager()

    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        return WKWebView(frame: .zero, configuration: configuration)
    }()

    private init() {}

    func goHome() {
        guard let url = URL(string: Config.shared.BASE_URL) else {
            print("WebViewManager: Invalid BASE_URL")
            return
        }
        print("WebViewManager: Navigating to home")
        webView.load(URLRequest(url: url))
    }
}
