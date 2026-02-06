import Foundation
import WebKit

class WebViewManager {
    static let shared = WebViewManager()

    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    private init() {}

    func goHome() {
        print("WebViewManager: Navigating to home")
        webView.load(URLRequest(url: Config.shared.BASE_URL))
    }
}
