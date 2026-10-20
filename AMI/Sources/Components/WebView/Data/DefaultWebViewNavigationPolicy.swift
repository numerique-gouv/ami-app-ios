//
//  DefaultWebViewNavigationPolicy.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
final class DefaultWebViewNavigationPolicy: WebViewNavigationPolicyDelegate {
    static let shared = DefaultWebViewNavigationPolicy()

    /// Always authorize navigation to any destination.
    func isNavigationAllowed(navigationAction: WKNavigationAction) async -> Bool {
        true
    }
}
