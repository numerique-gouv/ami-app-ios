//
//  WebViewNavigateToNewWindowDestination.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
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
