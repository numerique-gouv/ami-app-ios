//
//  DependencyContainer.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
enum DependencyContainer {
    ///  The object to handle web links like `mailto:` or `tel:`…
    private static let specialLinkHandler = SpecialLinkHandler()

    static let appState = AMIAppState()
    static let notificationManager = NotificationManager()
    // This common website DataStore will be injected n root views to be shared with all child webviews.
    private static let commonWebsiteDataStore: WKWebsiteDataStore = .default()

    private static let webViewDelegateSimulatorImplementation = WebViewDelegateSimulatorImplementation()

    /// ViewModel used by `SwiftUIWebView` preview in Xcode.
    static func makeSimulatorPreviewSwiftUIWebViewModel() -> SwiftUIWebView.ViewModel {
        let model = SwiftUIWebView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                             websiteDataStore: .nonPersistent(),
                                             specialLinkHandler: Self.specialLinkHandler,
                                             initialUserScripts: HomeUserScripts())
        model.delegate = Self.webViewDelegateSimulatorImplementation

        #if DEBUG
            model.acceptSelfSignedCertificate = true
        #endif

        return model
    }

    static func makePreviewHomeViewModel() -> HomeView.ViewModel {
        HomeView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                           websiteDataStore: .nonPersistent(),
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager)
    }

    static func makePreviewServiceViewModel() -> ServiceView.ViewModel {
        ServiceView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                              websiteDataStore: .nonPersistent(),
                              specialLinkHandler: specialLinkHandler) {
            AppLog.viewModel.log("\(AppLog.logHeader()) Back to home called")
        }
    }

    #if IS_AMI_STAGING
        static func makeReviewAppViewModel() -> ReviewAppView.ViewModel {
            ReviewAppView.ViewModel(websiteDataStore: commonWebsiteDataStore,
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }

        static func makePreviewReviewAppViewModel() -> ReviewAppView.ViewModel {
            ReviewAppView.ViewModel(websiteDataStore: .nonPersistent(),
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }
    #endif

    static func makeHomeViewModel() -> HomeView.ViewModel {
        HomeView.ViewModel(rootUrl: Config.shared.BASE_URL,
                           websiteDataStore: commonWebsiteDataStore,
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager)
    }

    static func makeReviewAppHomeViewModel(rootUrl: URL) -> HomeView.ViewModel {
        HomeView.ViewModel(rootUrl: rootUrl,
                           websiteDataStore: commonWebsiteDataStore,
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager)
    }
}
