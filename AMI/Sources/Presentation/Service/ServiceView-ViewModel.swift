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

        init(rootUrl: URL,
             websiteDataStore: WKWebsiteDataStore,
             refererUrl: URL? = nil,
             specialLinkHandler: any SpecialLinkProtocol,
             backToHomeAction: BackToHomeAction?) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let navigationHandler = ServiceViewNavigationHandler(rootUrl: rootUrl,
                                                                 specialLinkHandler: specialLinkHandler)
            let userScripts = ServiceViewUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            websiteDataStore: websiteDataStore,
                                                            navigationHandler: navigationHandler,
                                                            refererUrl: refererUrl,
                                                            initialUserScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.backToHomeAction = backToHomeAction

            super.init()

            // Inject ServiceViewModel into ServiceViewNavigationHandler now that `self` is initialized.
            navigationHandler.viewModel = self

            self.webViewViewModel.navigateToNewWindowManager = self

            AppLog.viewModel.debug("\(AppLog.logHeader(self)) init")
        }

        func destinationLinkViewDismissed() {
            AppLog.viewModel.log("\(AppLog.logHeader(self)) call")
            selectedDestination = nil
        }

        deinit {
            AppLog.viewModel.debug("\(AppLog.logHeader(self)) deinit")
        }
    }
}
