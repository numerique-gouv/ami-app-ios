//
//  ServiceViewNavigateToNewWindow.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension ServiceView.ViewModel: @MainActor WebViewNavigateToNewWindow {
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
