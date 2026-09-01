//
//  WebViewNavigateToNewWindowProtocol.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

public enum WebViewNavigateToNewWindowDestination {
    /// Load the URL in the current web view.
    case currentWebView
    /// Load the URL in a new WKWebView.
    case newWebView
    /// Open the URL in the system browser (Safari).
    case externalBrowser
}

protocol WebViewNavigateToNewWindowProtocol {
    /// Decide how to handle a new-window navigation request.
    ///
    /// - Returns: An action the coordinator should execute.
    func destinationForNewWindow(
        sourceWebView: WKWebView,
        configuration: WKWebViewConfiguration,
        navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WebViewNavigateToNewWindowDestination
}
