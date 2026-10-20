//
//  WebViewNavigationPolicyDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

/// Decides whether a pending web view navigation should be allowed.
///
/// Use this to centralize navigation rules for a web view  (internal vs. external links,
/// promoted URLs, takeovers).
nonisolated protocol WebViewNavigationPolicyDelegate: AnyObject, Sendable {
    /// Evaluates a navigation request and decides whether it should proceed in the web view.
    ///
    /// - Parameters:
    ///   - navigationAction: The pending request, as delivered by `WKNavigationDelegate`.
    /// - Returns: `true` to allow the navigation in the web view, `false` to cancel it.
    func isNavigationAllowed(navigationAction: WKNavigationAction) async -> Bool
}
