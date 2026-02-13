import Foundation
import WebKit

class WebViewManager {
    static let shared = WebViewManager()
    private var homeUrl: URL?

    let webView: WKWebView = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()

    private init() {}

    func setHome(homeUrl: URL) {
        self.homeUrl = homeUrl
    }

    func goHome() {
        guard let homeUrl else {
            print("WebViewManager Error: Navigating to home but homeUrl is undefined.")
            return
        }

        print("WebViewManager: Navigating to home")
        webView.load(URLRequest(url: homeUrl))
    }
}
