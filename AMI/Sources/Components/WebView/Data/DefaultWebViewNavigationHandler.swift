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
    /// The Certificate Pinning Feature of the webview
    var certificatePinning: CertificatePinningFeature?
    /// The promoted urls feature of the webview.
    var promotedUrls: PromotedUrlsFeature?
    /// The handler to detect and activate special links.
    let specialLinkHandler: any SpecialLinkProtocol

    init(rootUrl: URL,
         certificatePinning: CertificatePinningFeature?,
         promotedUrls: PromotedUrlsFeature?,
         specialLinkHandler: any SpecialLinkProtocol) {
        self.rootUrl = rootUrl
        self.certificatePinning = certificatePinning
        self.promotedUrls = promotedUrls
        self.specialLinkHandler = specialLinkHandler
    }

    /// Always authorize navigation to any destination.
    func navigationType(for navigationAction: WKNavigationAction) async -> WebViewNavigationType {
        .sameWebview
    }

    /// Called before starting the navigation to destination.
    func prepareNavigation(to destination: WebViewNavigationType) {}

    func evaluateAuthChallenge(challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        (.performDefaultHandling, nil)
    }
}
