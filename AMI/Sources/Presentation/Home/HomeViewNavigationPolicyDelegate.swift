//
//  HomeViewNavigationPolicyDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension HomeView.ViewModel: WebViewNavigationPolicyDelegate {
    @MainActor
    // TODO: this method should only decide to allow of forbid the navigation and should not modify state.
    func isNavigationAllowed(navigationAction: WKNavigationAction) async -> Bool {
        guard let targetUrl = navigationAction.request.url else {
            // No special restriction. Return TRUE.
            return true
        }

        // PromotedUrls Feature
        //
        // Intercept only tapped link or navigation triggered by the web app.
        if [WKNavigationType.linkActivated, WKNavigationType.other].contains(navigationAction.navigationType),
           let promotedUrl = try? await promotedUrls?.handleNavigationUseCase.handle(url: targetUrl) {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) checkIfNavigationIsAllowed Promoted URL detected: \(targetUrl)")
            switch promotedUrl {
            case .amiNotificationsSettings:
                showSettings = true
                // Although a promoted page will be presented, the initial navigation still occurs (Single Page Application side-effect?)
                // So, go back to the previous page.
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    webViewViewModel.goBack()
                }
                // Block initial navigation as a promoted page is presented.
                return false
            default:
                break
            }
            // Allow initial navigation
            return true
        }

        let targetUrlHost = targetUrl.host()

        #if IS_AMI_PRODUCTION
            // Special case of FranceIdentité application URL.
            // Accessing this URL should launch France Identité application if installed
            // or France Identité website in external Safari browser if the application is not present on the device.
            if targetUrlHost == Secrets.franceidentiteHost {
                await UIApplication.shared.open(targetUrl)
                return false
            }
        #endif

        // Special case of OIDC web page for HomeView
        // Continue normal navigation inside the Home webView.
        //
        // Connection pages is special for now because we can be blocked
        // on France Connect page when loging out without any way to exit the error page.
        // So let's the back button be present.
        //
        if let targetUrlHost,
           Config.shared.OIDC_HOSTS.contains(targetUrlHost) {
            showBackButton = true
            return true
        } else {
            showBackButton = false
        }

        // Special case of "about:blank" (used on FI impots.gouv.fr)
        if targetUrlHost == nil {
            return true
        }

        // Special process for destination Url
        // If the destination url is outside the root domain, open as a Service in a dedicated webview.
        if !targetUrl.absoluteString.hasPrefix(webViewViewModel.rootUrl.absoluteString) {
            selectedDestination = ServiceLinkViewModel(destinationUrl: targetUrl,
                                                       dataStore: webViewViewModel.configuration.websiteDataStore,
                                                       sourceUrl: webViewViewModel.webView?.url,
                                                       specialLinkHandler: webViewViewModel.specialLinkHandler) { [weak self] in
                self?.destinationLinkViewDismissed()
            }
            // Go back to previous page in originating webview.
            Task { @MainActor in
                webViewViewModel.goBack()
            }
            return false
        }

        return true
    }
}
