//
//  ServiceViewNavigationHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 21/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

final class ServiceViewNavigationHandler: WebViewNavigationHandler {
    let rootUrl: URL
    let specialLinkHandler: any SpecialLinkProtocol
    weak var promotedUrls: PromotedUrlsFeature?
    weak var viewModel: ServiceView.ViewModel?

    init(rootUrl: URL, specialLinkHandler: any SpecialLinkProtocol) {
        self.rootUrl = rootUrl
        self.specialLinkHandler = specialLinkHandler
    }

    /// Returns the navigation type decided from the navigation action.
    ///
    /// - Parameters: `navigationAction` the navigation action to analyze
    /// - Returns: the associated `WebViewNavigationType`
    func navigationType(for navigationAction: WKNavigationAction) async -> WebViewNavigationType {
        guard let targetUrl = navigationAction.request.url else {
            // No special restriction..
            return .sameWebview
        }

        // Check if link is explicitly marked as a download (e.g. <a download>) or is a downlodable destination for the application.
        if navigationAction.shouldPerformDownload || WebViewDownloadCoordinator.destinationUrlIsDownloadableFile(targetUrl) {
            return .downloadLink
        }

        // Check if it is a special link to intercept and dispatch to the operating system.
        if let specialLink = specialLinkHandler.specialLink(for: targetUrl) {
            return .specialLink(specialLink)
        }

        // Special process for destination Url
        // If the destination url is outside the root domain, open as a Service in a dedicated webview.
        if !targetUrl.absoluteString.hasPrefix(rootUrl.absoluteString) {
            return .otherDomain(targetUrl)
        }

        return .sameWebview
    }

    /// Called before starting the navigation to destination.
    func prepareNavigation(to destination: WebViewNavigationType) {
        guard let viewModel else {
            return
        }

        let webViewViewModel = viewModel.webViewViewModel

        switch destination {
        case let .promotedUrl(appRoute):
            AppLog.service.error("\(AppLog.logHeader(self)) Promoted URLs in ServiceView shouldn't occur. (AppRoute: \(appRoute)")
            fatalError("Promoted URLs in ServiceView shouldn't occur. (AppRoute: \(appRoute)")
        case let .otherDomain(domainUrl):
            viewModel.selectedDestination = ServiceLinkViewModel(destinationUrl: domainUrl,
                                                                 dataStore: webViewViewModel.configuration.websiteDataStore,
                                                                 sourceUrl: webViewViewModel.webView?.url,
                                                                 specialLinkHandler: specialLinkHandler) { [weak viewModel] in
                viewModel?.destinationLinkViewDismissed()
            }
            // Go back to previous page in originating webview.
            Task { @MainActor in
                webViewViewModel.goBack()
            }
        default:
            break
        }
    }
}
