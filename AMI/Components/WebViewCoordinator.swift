//
//  WebViewCoordinator.swift
//  AMI
//
//  Created by Aline Bonnet on 22/12/2025.
//

import Foundation
@preconcurrency import WebKit
import SwiftUI

class WebViewCoordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: WebView
    private var progressObservation: NSKeyValueObservation?
    private var isLoadingBinding: Binding<Bool>
    private var loadingProgressBinding: Binding<Double>

    init(_ parent: WebView, isLoading: Binding<Bool>, loadingProgress: Binding<Double>) {
        self.parent = parent
        self.isLoadingBinding = isLoading
        self.loadingProgressBinding = loadingProgress
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Show loader immediately on link click (before page starts loading)
        DispatchQueue.main.async {
            self.isLoadingBinding.wrappedValue = true
            self.loadingProgressBinding.wrappedValue = 0.0
        }

        guard let urlString = navigationAction.request.url?.absoluteString else { return }
        parent.isExternalProcess = !urlString.contains(Config.shared.BASE_URL)

        print("WebView: 📍 Navigation to: \(urlString)")

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        #if DEBUG
        // In debug builds, accept self-signed certificates
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
        default:
            return
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.async {
            self.isLoadingBinding.wrappedValue = false
        }
    }

    func observeProgress(of wkWebView: WKWebView) {
        progressObservation = wkWebView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.loadingProgressBinding.wrappedValue = webView.estimatedProgress
            }
        }
    }
}
