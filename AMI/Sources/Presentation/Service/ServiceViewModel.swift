//
//  ServiceViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit
import WebKit

@MainActor
@Observable
class ServiceViewModel: NSObject {
    typealias BackToHomeAction = () -> Void

    let webViewViewModel: SwiftUIWebView.ViewModel

    let notificationManager: NotificationManager

    var backToHomeAction: BackToHomeAction?

    var selectedDestination: ServiceLinkViewModel?

    init(rootUrl: URL,
         websiteDataStore: WKWebsiteDataStore,
         refererUrl: URL? = nil,
         specialLinkHandler: any SpecialLinkProtocol,
         notificationManager: NotificationManager,
         backToHomeAction: BackToHomeAction?) {
        // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
        let navigationHandler = ServiceViewNavigationHandler(rootUrl: rootUrl,
                                                             specialLinkHandler: specialLinkHandler)
        let defaultNavigationState = DefaultWebViewNavigationState()

        let userScripts = ServiceViewUserScripts()
        let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                        websiteDataStore: websiteDataStore,
                                                        navigationHandler: navigationHandler,
                                                        navigationState: defaultNavigationState,
                                                        refererUrl: refererUrl,
                                                        initialUserScripts: userScripts)
        self.notificationManager = notificationManager
        self.webViewViewModel = webViewViewModel
        self.backToHomeAction = backToHomeAction

        super.init()

        // Inject ServiceViewModel into ServiceViewNavigationHandler now that `self` is initialized.
        navigationHandler.viewModel = self

        self.webViewViewModel.navigateToNewWindowManager = self

        AppLog.viewModel.debug("\(AppLog.logHeader(self)) Init Service view model for url: \(rootUrl)")
    }

    func backToHomeViewAction() {
        AppLog.viewModel.log("\(AppLog.logHeader(self)) call")
        selectedDestination = nil
    }

    deinit {
        AppLog.viewModel.debug("\(AppLog.logHeader(self)) deinit")
    }
}
