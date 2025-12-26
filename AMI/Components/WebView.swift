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
    let initialURL: String
    @Binding var isExternalProcess: Bool
    @Binding var webViewRef: WKWebView?

    func makeUIView(context: Context) -> some UIView {
        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController

        #if DEBUG
            ConsoleLog.attach(contentController, context)
        #endif

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        webView.load(URLRequest(url: URL(string: initialURL)!))

        DispatchQueue.main.async { // Do not modify the state during view update.
            webViewRef = webView
        }

        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
}
