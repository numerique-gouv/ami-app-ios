//
//  WebViewNavigationType.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

enum WebViewNavigationType: Sendable {
    /// Navigation should occur normally in the curent webview.
    case sameWebview
    /// A promoted url with its associated `AppRoute` targeting a native view.
    case promotedUrl(AppRoute)
    #if IS_AMI_PRODUCTION
        /// Special case of FranceIdentité application URL.
        /// Accessing this URL should launch France Identité application if installed
        /// or France Identité website in external Safari browser if the application is not present on the device.
        case franceIdentiteApplication
    #endif
    /// Special case of OIDC web page for HomeView.
    /// Continue normal navigation inside the Home webView.
    case oidcDomain(URL)
    /// Special case of "about:blank" (used on FI impots.gouv.fr)
    case aboutBlank
    /// If the destination url is outside the root domain, open as a Service in a dedicated webview.
    case otherDomain(URL)
    /// A link is explicitly marked as a download (e.g. <a download>) or a downlodable destination for the application.
    case downloadLink
    /// A special link as `mailto` or `tel` that should be intercepted and handled by the operating system.
    case specialLink(SpecialLinkType)

    /// The `WKNavigationActionPolicy` (.allow, .cancel, .download) associated to each navigation type.
    var navigationPoliciy: WKNavigationActionPolicy {
        switch self {
        case .sameWebview: .allow
        case .promotedUrl: .cancel
        #if IS_AMI_PRODUCTION
            case .franceIdentiteApplication: .allow
        #endif
        case .oidcDomain: .allow
        case .aboutBlank: .allow
        case .otherDomain: .cancel
        case .downloadLink: .download
        case .specialLink: .cancel
        }
    }
}
