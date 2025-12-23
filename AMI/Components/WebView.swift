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
        let config = WKWebViewConfiguration()

        // Add message handler for JavaScript bridge
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "NativeBridge")

        // Inject JavaScript bridge to match Android interface
        // This creates window.NativeBridge.onEvent() that wraps the iOS messaging
        let bridgeScript = WKUserScript(
            source: """
            window.NativeBridge = {
                onEvent: function(eventName, data) {
                    window.webkit.messageHandlers.NativeBridge.postMessage({
                        event: eventName,
                        data: data
                    });
                }
            };
            console.log('NativeBridge initialized for iOS');
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(bridgeScript)
        config.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        DispatchQueue.main.async { // Do not modify the state during view update.
            webViewRef = webView
        }
        
        webView.load(URLRequest(url: URL(string: initialURL)!))
        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
    
    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self)
    }
}
