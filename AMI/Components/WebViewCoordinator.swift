//
//  WebViewCoordinator.swift
//  AMI
//
//  Created by Aline Bonnet on 22/12/2025.
//

import Foundation
@preconcurrency import WebKit

class WebViewCoordinator: NSObject, WKNavigationDelegate {
    var parent: WebView
    
    init(_ parent: WebView) {
        self.parent = parent
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let urlString = navigationAction.request.url?.absoluteString else { return }
        parent.isExternalProcess = !urlString.contains(Config.shared.BASE_URL)

        print("WebView: 📍 Navigation to: \(urlString)")

        decisionHandler(.allow)
    }
}
