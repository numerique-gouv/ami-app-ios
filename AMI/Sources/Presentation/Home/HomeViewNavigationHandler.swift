//
//  HomeViewNavigationHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

final class HomeViewNavigationHandler: WebViewNavigationHandler {
    let rootUrl: URL
    let specialLinkHandler: any SpecialLinkProtocol
    weak var promotedUrls: PromotedUrlsFeature?
    weak var viewModel: HomeView.ViewModel?

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

        // PromotedUrls Feature
        //
        // Intercept only tapped link or navigation triggered by the web app.
        if [WKNavigationType.linkActivated, WKNavigationType.other].contains(navigationAction.navigationType),
           let promotedUrl = try? await promotedUrls?.handleNavigationUseCase.handle(url: targetUrl) {
            return .promotedUrl(promotedUrl)
        }

        let targetUrlHost = targetUrl.host()

        #if IS_AMI_PRODUCTION
            // Special case of FranceIdentité application URL.
            // Accessing this URL should launch France Identité application if installed
            // or France Identité website in external Safari browser if the application is not present on the device.
            if targetUrlHost == Secrets.franceidentiteHost {
                return .franceIdentiteApplication
            }
        #endif

        // Special case of OIDC web page for HomeView.
        // Continue normal navigation inside the Home webView.
        //
        // Connection pages is special for now because we can be blocked
        // on France Connect page when loging out without any way to exit the error page.
        // So let's the back button be present.
        //
        if let targetUrlHost,
           Config.shared.OIDC_HOSTS.contains(targetUrlHost) {
            return .oidcDomain(targetUrl)
        }

        // Special case of "about:blank" (used on FI impots.gouv.fr)
        if targetUrlHost == nil {
            return .sameWebview
        }

        // Special process for destination Url
        // If the destination url is outside the root domain, open as a Service in a dedicated webview.
        if !targetUrl.absoluteString.hasPrefix(rootUrl.absoluteString) {
            return .otherDomain(targetUrl)
        }

        return .sameWebview
    }

    /// Called before starting the navigation to destination.
    @MainActor
    func prepareNavigation(to destination: WebViewNavigationType) {
        guard let viewModel else {
            return
        }

        let webViewViewModel = viewModel.webViewViewModel

        switch destination {
        case let .promotedUrl(appRoute):
            switch appRoute {
            case .amiNotificationsSettings:
                viewModel.showSettings = true
                // Although a promoted page will be presented, the initial navigation still occurs (Single Page Application side-effect?)
                // So, go back to the previous page.
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    webViewViewModel.goBack()
                }
            default:
                break
            }
        case .oidcDomain:
            viewModel.showBackButton = true
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
            viewModel.showBackButton = false
        }
    }
}
