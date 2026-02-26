//
//  HomeView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension HomeView {
    @Observable
    class ViewModel: NSObject {
        let webViewViewModel: SwiftUIWebView.ViewModel

        var isExternalProcess = false
        var isOnContactPage = false
        var shouldPresentSettings = false

//        var rootUrl: URL {
//            webViewViewModel.rootUrl
//        }

//        { [weak self] webView, value in
//            guard let self else { return }
//            print("WebView: URL changed to: \(webView.url?.absoluteString ?? "nil")")
//
//            // Check if webview activated application settings access.
//            if let targetUrl = value.newValue,
//               let targetUrlString = targetUrl?.absoluteString,
//               targetUrlString.hasSuffix("/#/settings") {
//                print("WebView: 📍 Application settings requested")
//                parent.shouldPresentSettings = true
//
//                // As new page should not be handled by webview, reset webView last step navigation (to clean history).
//                if webView.canGoBack {
//                    webView.goBack()
//                }
//                return
//            }
//
//            updateNotificationStatusInLocalStorage(webView: webView)
//            guard let urlString = webView.url?.absoluteString else { return }
//            Task { @MainActor in
//                self.isOnContactPageBinding.wrappedValue = urlString.contains("/#/contact")
//            }
//        }

        @Sendable private func handleUrlChange(webViewViewModel: SwiftUIWebView.ViewModel, url: URL?) {
            print("[URL Change Action] \(url?.debugDescription ?? "<nil>")")

            shouldPresentSettings = url?.absoluteString.hasSuffix("/#/settings") ?? false
            isOnContactPage = url?.absoluteString.hasSuffix("/#/contact") ?? false
            isExternalProcess = !(url?.absoluteString.hasPrefix(webViewViewModel.rootUrl.absoluteString) ?? true)
            
            Task { @MainActor in
                if self.shouldPresentSettings,
                   self.webViewViewModel.webView?.canGoBack ?? false {
                    // As new page should not be handled by webview, reset webView last step navigation (to clean history).
                    self.webViewViewModel.webView?.goBack()
                }
            }
        }

        init(rootUrl: URL) {
            webViewViewModel = SwiftUIWebView.ViewModel(configuration: WKWebViewConfiguration(),
                                                        rootUrl: rootUrl,
                                                        delegate: HomeViewDelegate(),
                                                        userScripts: HomeUserScripts())
            super.init()

            // Init `urlChangeAction` property after fully initialized `self` because closure is referencing `self`.
            // No clean way to pass this closure in the `SwiftUIWebView.ViewModel.init` call.
            webViewViewModel.urlChangeAction = handleUrlChange
        }
    }
}

class HomeViewDelegate: WebViewDelegate {
    func navigationWillStart(navigationAction: WKNavigationAction) {
        print("[WebViewDelegate navigationWillStart]")
    }

    func navigationDidStart() {
        print("[WebViewDelegate navigationDidStart]")
    }

    func navigationDidFinish() {
        print("[WebViewDelegate navigationDidFinish]")
    }

    func navigationDidFailed(withError error: Error) {
        print("[WebViewDelegate navigationDidFailed] failed with error \(error)")
    }
}
