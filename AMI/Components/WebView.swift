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
    @State var webView: WKWebView = WKWebView()

    func makeUIView(context: Context) -> some UIView {
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
