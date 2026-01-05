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
    @Binding var isExternalProcess: Bool
    @Binding var currentURL: String
    @Binding var lastURL: String
    @State var webView: WKWebView = WKWebView()
    
    func makeUIView(context: Context) -> some UIView {
        webView.navigationDelegate = context.coordinator
        context.coordinator.observeURL(of: self)
        webView.load(URLRequest(url: URL(string: currentURL)!))
        return webView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        webView.load(URLRequest(url: URL(string: currentURL)!))
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
}
