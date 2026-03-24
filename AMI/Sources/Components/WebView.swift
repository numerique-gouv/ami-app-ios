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

        // Make sure to cleanup the potential existing content controllers before trying to add them again.
        // WebView is a singleton, so it's reused for example when going back to the review app screen to
        // select another review app.
        contentController.removeAllScriptMessageHandlers()
        contentController.removeAllUserScripts()
        NativeEvents.attach(contentController, context.coordinator)

        #if DEBUG
            ConsoleLog.attach(contentController, context.coordinator)
        #endif

        webView.navigationDelegate = context.coordinator
        context.coordinator.observeProgress(of: webView)
        let urlToLoad = WebViewManager.shared.pendingURL ?? initialUrl
        WebViewManager.shared.pendingURL = nil
        webView.load(URLRequest(url: urlToLoad))

        return webView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator(self, isLoading: $isLoading, loadingProgress: $loadingProgress, isOnContactPage: $isOnContactPage)
    }
}
