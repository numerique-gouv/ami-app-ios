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
        typealias BackToHomeAction = () -> Void

        let webViewViewModel: SwiftUIWebView.ViewModel

        var showNoEmailClientAlert = false

        private var checkNotificationStatusDone = false

        var backToHomeAction: BackToHomeAction?

        @MainActor
        func contactByEmail(targetUrl: URL) {
            UIApplication.shared.open(targetUrl) { accepted in
                self.showNoEmailClientAlert = !accepted
            }
        }

        init(websiteDataStore: WKWebsiteDataStore, rootUrl: URL, backToHomeAction: BackToHomeAction?) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let userScripts = PartnerUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(websiteDataStore: websiteDataStore,
                                                            rootUrl: rootUrl,
                                                            userScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.backToHomeAction = backToHomeAction
            super.init()

            self.webViewViewModel.delegate = self

            AppLog.viewModel.debug("\(AppLog.logHeader(self)) PartnerView.ViewModel init")
        }

        deinit {
            AppLog.viewModel.debug("\(AppLog.logHeader(self)) PartnerView.ViewModel deinit")
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
