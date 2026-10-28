//
//  WebViewNavigationHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 21/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

/// Decides whether a pending web view navigation should be allowed.
///
/// Use this to centralize navigation rules for a web view  (internal vs. external links,
/// promoted URLs, takeovers).
@MainActor
protocol WebViewNavigationHandler: AnyObject {
    /// The root url of the webview.
    var rootUrl: URL { get }
    /// The promoted urls feature of the webview.
    var promotedUrls: PromotedUrlsFeature? { get }
    /// The handler to detect and activate special links.
    var specialLinkHandler: any SpecialLinkProtocol { get }

    /// Returns the navigation type decided from the navigation action.
    ///
    /// - Parameters: `navigationAction` the navigation action to analyze
    /// - Returns: the associated `WebViewNavigationType`
    func navigationType(for navigationAction: WKNavigationAction) async -> WebViewNavigationType

    /// Called before starting the navigation to destination.
    func prepareNavigation(to destination: WebViewNavigationType)
}
