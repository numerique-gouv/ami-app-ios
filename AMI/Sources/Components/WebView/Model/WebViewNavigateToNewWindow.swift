//
//  WebViewNavigateToNewWindow.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

protocol WebViewNavigateToNewWindow: AnyObject {
    /// Decide how to handle a new-window navigation request.
    ///
    /// - Returns: An action the coordinator should execute.
    func destinationForNewWindow(
        sourceWebView: WKWebView,
        configuration: WKWebViewConfiguration,
        navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WebViewNavigateToNewWindowDestination

    /// Called when `destinationForNewWindow` returns `.newWebView`
    ///
    /// The protocol adopter must decide how to load the new webView with the destination url.
    func loadInNewWebView(url: URL)
}
