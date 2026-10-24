//
//  DefaultWebViewNavigateToNewWindow.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

final class DefaultWebViewNavigateToNewWindow: WebViewNavigateToNewWindow {
    static let shared = DefaultWebViewNavigateToNewWindow()

    /// Default behavior: open all links in current webview.
    func destinationForNewWindow(sourceWebView: WKWebView,
                                 configuration: WKWebViewConfiguration,
                                 navigationAction: WKNavigationAction,
                                 windowFeatures: WKWindowFeatures) -> WebViewNavigateToNewWindowDestination {
        .currentWebView
    }

    /// Forbid loading of any link in new webview.
    func loadInNewWebView(url: URL) {
        fatalError("Should never happen on base WebView-ViewModel.")
    }
}
