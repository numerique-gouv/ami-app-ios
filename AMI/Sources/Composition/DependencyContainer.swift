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
    static let deviceIdProvider = LocalStorageDeviceIDProvider()
    static let notificationManager = NotificationManager(deviceIdProvider: deviceIdProvider)
    // This common website DataStore will be injected n root views to be shared with all child webviews.
    private static let commonWebsiteDataStore: WKWebsiteDataStore = .default()

    /// ViewModel used by `SwiftUIWebView` preview in Xcode.
    static func makeSimulatorPreviewSwiftUIWebViewModel() -> SwiftUIWebView.ViewModel {
        let rootUrl = URL(string: "https://numerique.gouv.fr")!
        let model = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                             websiteDataStore: .nonPersistent(),
                                             navigationHandler: DefaultWebViewNavigationHandler(rootUrl: rootUrl, specialLinkHandler: specialLinkHandler),
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
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager,
                           deviceIdProvider: deviceIdProvider)
    }

    static func makePreviewOnboardingViewModel() -> OnboardingView.ViewModel {
        OnboardingView.ViewModel(notificationManager: notificationManager)
    }

    static func makePreviewServiceViewModel() -> ServiceView.ViewModel {
        ServiceView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                              websiteDataStore: .nonPersistent(),
                              specialLinkHandler: specialLinkHandler) {
            AppLog.viewModel.log("\(AppLog.logHeader()) Back to home called")
        }
    }

    static func makePreviewSettingsViewModel() -> SettingsView.ViewModel {
        SettingsView.ViewModel(notificationManager: NotificationManager(deviceIdProvider: deviceIdProvider))
    }

    #if IS_AMI_PRODUCTION || IS_AMI_PREPRODUCTION

        static func makeRootViewModel() -> HomeView.ViewModel {
            HomeView.ViewModel(rootUrl: Config.shared.BASE_URL,
                               websiteDataStore: commonWebsiteDataStore,
                               specialLinkHandler: specialLinkHandler,
                               notificationManager: notificationManager,
                               deviceIdProvider: deviceIdProvider)
        }

    #elseif IS_AMI_STAGING

        static func makeReviewAppsListViewModel() -> ReviewAppView.ViewModel {
            ReviewAppView.ViewModel(websiteDataStore: commonWebsiteDataStore,
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }

        static func makeReviewAppHomeViewModel(for rootUrl: URL) -> HomeView.ViewModel {
            HomeView.ViewModel(rootUrl: rootUrl,
                               websiteDataStore: commonWebsiteDataStore,
                               specialLinkHandler: specialLinkHandler,
                               notificationManager: notificationManager,
                               deviceIdProvider: deviceIdProvider)
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
                           notificationManager: notificationManager,
                           deviceIdProvider: deviceIdProvider)
    }

    static func makeReviewAppHomeViewModel(rootUrl: URL) -> HomeView.ViewModel {
        HomeView.ViewModel(rootUrl: rootUrl,
                           websiteDataStore: commonWebsiteDataStore,
                           specialLinkHandler: specialLinkHandler,
                           notificationManager: notificationManager,
                           deviceIdProvider: deviceIdProvider)
    }
}
