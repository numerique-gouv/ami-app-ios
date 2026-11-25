//
//  DependencyContainer.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation
import WebKit

@MainActor
enum DependencyContainer {
    ///  The object to handle web links like `mailto:` or `tel:`…
    private static let specialLinkHandler = SpecialLinkHandler()

    static let appState = AMIAppState()
    /// App-wide notification manager. Device registration runs over a
    /// `ServerTrustURLSession`: pinned in preproduction, system default elsewhere.
    static let notificationManager = {
        let trustedUrlSession = ServerTrustURLSession(handler: certificatePinningFeature, configuration: .default)
        return NotificationManager(registerDevice: RegisterDevice(trustedUrlSession: trustedUrlSession))
    }()

    // This common website DataStore will be injected in root views to be shared with all child webviews.
    private static let commonWebsiteDataStore: WKWebsiteDataStore = .default()

    /// ViewModel used by `SwiftUIWebView` preview in Xcode.
    static func makeSimulatorPreviewSwiftUIWebViewModel() -> SwiftUIWebView.ViewModel {
        let rootUrl = URL(string: "https://numerique.gouv.fr")!
        let model = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                             websiteDataStore: .nonPersistent(),
                                             navigationHandler: DefaultWebViewNavigationHandler(rootUrl: rootUrl,
                                                                                                certificatePinning: nil,
                                                                                                promotedUrls: nil,
                                                                                                specialLinkHandler: specialLinkHandler),
                                             navigationState: DefaultWebViewNavigationState(),
                                             initialUserScripts: HomeUserScripts())

        #if DEBUG
            model.acceptSelfSignedCertificate = true
        #endif

        return model
    }

    static func makePreviewHomeViewModel() -> HomeView.ViewModel {
        HomeView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                           websiteDataStore: .nonPersistent(),
                           certificatePinning: nil,
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager)
    }

    static func makePreviewServiceViewModel() -> ServiceView.ViewModel {
        ServiceView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                              certificatePinning: nil,
                              websiteDataStore: .nonPersistent(),
                              specialLinkHandler: specialLinkHandler) {
            AppLog.viewModel.log("\(AppLog.logHeader()) Back to home called")
        }
    }

    // Certificate pinning is only configured for PreProduction for the moment.
    #if IS_AMI_PRODUCTION
        private static let certificatePinningFeature: CertificatePinningFeature? = nil
    #elseif IS_AMI_PREPRODUCTION
        private static let certificatePinningFeature: CertificatePinningFeature? =
            CertificatePinningFeature(pinRules: [
                PinRule(pattern: Secrets.appPinnedDomainRegex,
                        pins: Secrets.appPinnedDomainSpkiSha256Base64.map {
                            PinFactory.spki.makePin(algorithm: .sha256, base64Representation: $0)
                        }),
            ])
    #elseif IS_AMI_STAGING
        // No certificate pinning for the moment.
        private static let certificatePinningFeature: CertificatePinningFeature? = nil
    #else
        // No certificate pinning for the moment.
        private static let certificatePinningFeature: CertificatePinningFeature? = nil
    #endif

    #if IS_AMI_PRODUCTION || IS_AMI_PREPRODUCTION

        static func makeRootViewModel() -> HomeView.ViewModel {
            HomeView.ViewModel(rootUrl: Config.shared.BASE_URL,
                               websiteDataStore: commonWebsiteDataStore,
                               certificatePinning: certificatePinningFeature,
                               specialLinkHandler: specialLinkHandler,
                               notificationManager: notificationManager)
        }

    #elseif IS_AMI_STAGING

        static func makeReviewAppsListViewModel() -> ReviewAppView.ViewModel {
            ReviewAppView.ViewModel(websiteDataStore: commonWebsiteDataStore,
                                    certificatePinning: certificatePinningFeature,
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }

        static func makePreviewReviewAppViewModel() -> ReviewAppView.ViewModel {
            ReviewAppView.ViewModel(websiteDataStore: .nonPersistent(),
                                    certificatePinning: nil,
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }

    #endif
}
