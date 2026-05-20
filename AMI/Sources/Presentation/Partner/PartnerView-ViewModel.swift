//
//  PartnerView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit
import WebKit

extension PartnerView {
    @Observable
    class ViewModel: NSObject {
        let webViewViewModel: SwiftUIWebView.ViewModel

        var showNoEmailClientAlert = false

        private var checkNotificationStatusDone = false

        @MainActor
        func contactByEmail(targetUrl: URL) {
            UIApplication.shared.open(targetUrl) { accepted in
                self.showNoEmailClientAlert = !accepted
            }
        }

        init(configuration: WKWebViewConfiguration, rootUrl: URL) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let userScripts = PartnerUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(configuration: configuration,
                                                            rootUrl: rootUrl,
                                                            userScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            super.init()

            self.webViewViewModel.delegate = self
        }
    }
}

extension PartnerView.ViewModel: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        guard let targetUrl = navigationAction.request.url else {
            // No special restriction. Return TRUE.
            return true
        }

        // Special process for `mailto` url.
        if targetUrl.scheme == "mailto" {
            Task { @MainActor in
                contactByEmail(targetUrl: targetUrl)
            }
            return false
        }

        return true
    }

    func navigationWillStart(navigationAction: WKNavigationAction) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationWillStart")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidStart")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidFinish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidFailed] failed with error \(error)")
    }
}
