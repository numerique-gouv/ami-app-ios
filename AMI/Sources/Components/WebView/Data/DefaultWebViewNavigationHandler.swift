//
//  DefaultWebViewNavigationHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

final class DefaultWebViewNavigationHandler: WebViewNavigationHandler {
    /// The root url of the webview.
    let rootUrl: URL
    /// The promoted urls feature of the webview.
    var promotedUrls: PromotedUrlsFeature?
    /// The
    let specialLinkHandler: any SpecialLinkProtocol

    init(rootUrl: URL, promotedUrls: PromotedUrlsFeature? = nil, specialLinkHandler: any SpecialLinkProtocol) {
        self.rootUrl = rootUrl
        self.promotedUrls = promotedUrls
        self.specialLinkHandler = specialLinkHandler
    }

    /// Always authorize navigation to any destination.
    func navigationType(for navigationAction: WKNavigationAction) async -> WebViewNavigationType {
        .sameWebview
    }

    /// Called before starting the navigation to destination.
    func prepareNavigation(to destination: WebViewNavigationType) {}
}
