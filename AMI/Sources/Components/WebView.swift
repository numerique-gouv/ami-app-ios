//
//  WebView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import Foundation
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let initialUrl: URL
    @Binding var isExternalProcess: Bool
    @Binding var isLoading: Bool
    @Binding var loadingProgress: Double
    @Binding var isOnContactPage: Bool
    @Binding var shouldPresentSettings: Bool

    func makeUIView(context: Context) -> some UIView {
        let webView = WebViewManager.shared.webView
        let contentController = webView.configuration.userContentController

        NativeEvents.attach(contentController, context.coordinator)

        #if DEBUG
            ConsoleLog.attach(contentController, context.coordinator)
        #endif

        webView.navigationDelegate = context.coordinator
        context.coordinator.observeProgress(of: webView)
        webView.load(URLRequest(url: initialUrl))

        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self, isLoading: $isLoading, loadingProgress: $loadingProgress, isOnContactPage: $isOnContactPage)
    }
}
