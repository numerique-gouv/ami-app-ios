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
    @Observable
    class ViewModel: NSObject {
        typealias BackToHomeAction = () -> Void

        let webViewViewModel: SwiftUIWebView.ViewModel

        private var checkNotificationStatusDone = false

        var backToHomeAction: BackToHomeAction?

        var selectedDestination: ServiceLinkViewModel?

        private let receivePSLFinalPayload: ReceivePSLFinalPayloadUseCase

        init(rootUrl: URL,
             websiteDataStore: WKWebsiteDataStore,
             refererUrl: URL? = nil,
             specialLinkHandler: SpecialLinkHandler,
             receivePSLFinalPayload: ReceivePSLFinalPayloadUseCase,
             backToHomeAction: BackToHomeAction?) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            websiteDataStore: websiteDataStore,
                                                            specialLinkHandler: specialLinkHandler,
                                                            refererUrl: refererUrl)
            self.webViewViewModel = webViewViewModel
            self.receivePSLFinalPayload = receivePSLFinalPayload
            self.backToHomeAction = backToHomeAction

            super.init()

            webViewViewModel.addUserScripts(userScripts: ServiceViewUserScripts(), handler: self)
            webViewViewModel.addUserScripts(userScripts: ServiceViewPostMessageScripts(context: self), handler: self)

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

        func receivePSLFinalPayload(payload: Data) async {
            do {
                _ = try await receivePSLFinalPayload.execute(payload: payload)
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) Saved received PSF final payload")
            } catch {
                AppLog.viewModel.error("\(AppLog.logHeader(self)) Error with received PSF final payload: \(error)")
            }
        }
    }
}

        var receivedContent: InfoPanelContent?
    }
}

extension ServiceView.ViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        webViewViewModel.userContentController(userContentController, didReceive: message)
    }
}

extension ServiceView.ViewModel: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        true
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

extension ServiceView.ViewModel: WebViewNavigateToNewWindowProtocol {
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
                                                   specialLinkHandler: webViewViewModel.specialLinkHandler,
                                                   receivePSLFinalPayload: receivePSLFinalPayload) { [weak self] in
            self?.destinationLinkViewDismissed()
        }
    }
}
