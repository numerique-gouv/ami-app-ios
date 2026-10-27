//
//  ServiceView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension ServiceView {
    @MainActor
    @Observable
    class ViewModel: NSObject {
        typealias BackToHomeAction = () -> Void

        let webViewViewModel: SwiftUIWebView.ViewModel

        private var checkNotificationStatusDone = false

        var backToHomeAction: BackToHomeAction?

        var selectedDestination: ServiceLinkViewModel?

        // UrlInterception Feature
        private var urlInterception: UrlInterceptionFeature

        init(rootUrl: URL,
             websiteDataStore: WKWebsiteDataStore,
             refererUrl: URL? = nil,
             specialLinkHandler: SpecialLinkHandler,
             backToHomeAction: BackToHomeAction?) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let userScripts = ServiceViewUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            websiteDataStore: websiteDataStore,
                                                            specialLinkHandler: specialLinkHandler,
                                                            refererUrl: refererUrl,
                                                            initialUserScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.backToHomeAction = backToHomeAction

            // UrlInterception Feature
            //
            urlInterception = UrlInterceptionFeature()

            super.init()

            self.webViewViewModel.delegate = self

            self.webViewViewModel.navigateToNewWindowManager = self

            AppLog.viewModel.debug("\(AppLog.logHeader(self)) init")
        }

        private func destinationLinkViewDismissed() {
            AppLog.viewModel.log("\(AppLog.logHeader(self)) call")
            selectedDestination = nil
        }

        deinit {
            AppLog.viewModel.debug("\(AppLog.logHeader(self)) deinit")
        }
    }
}

extension ServiceView.ViewModel: @MainActor WebViewDelegate {
    func checkIfNavigationIsAllowed(webView: WKWebView, navigationAction: WKNavigationAction) async -> Bool {
        // UrlInterception Feature
        //
        if let originalUrl = navigationAction.request.url,
           [WKNavigationType.linkActivated, WKNavigationType.other].contains(navigationAction.navigationType),
           let rewrittenUrl = urlInterception.rewriteUrl.rewrite(url: originalUrl) {
            webView.load(URLRequest(url: rewrittenUrl))
            return false
        }

        return true
    }

    func navigationWillStart(navigationAction: WKNavigationAction) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationWillStart")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidStart")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidFinish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidFailed] failed with error \(error)")
    }
}

extension ServiceView.ViewModel: @MainActor WebViewNavigateToNewWindowProtocol {
    /// Default behavior: open all links in new webview.
    func destinationForNewWindow(sourceWebView: WKWebView,
                                 configuration: WKWebViewConfiguration,
                                 navigationAction: WKNavigationAction,
                                 windowFeatures: WKWindowFeatures) -> WebViewNavigateToNewWindowDestination {
        .newWebView
    }

    func loadInNewWebView(url: URL) {
        selectedDestination = ServiceLinkViewModel(destinationUrl: url,
                                                   dataStore: webViewViewModel.configuration.websiteDataStore,
                                                   sourceUrl: nil,
                                                   specialLinkHandler: webViewViewModel.specialLinkHandler) { [weak self] in
            self?.destinationLinkViewDismissed()
        }
    }
}
