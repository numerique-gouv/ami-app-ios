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
    /// A concrete Notification Event Publisher based on an AsyncStream.
    /// It publishes notification events to the unique RootViewModel that handles them.
    private static let notificationEventObserverFeature = NotificationEventObserverFeature(publisher: NotificationEventPublisherDataModule.makePublisher())
    /// The notification manager that forwards received notifications to a Notification Events Publisher.
    private static let notificationManager = NotificationManager(eventPublisher: notificationEventObserverFeature.publisher)
    /// This common website DataStore will be injected in root views to be shared with all child webviews.
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

    static func makeNotificationManager() -> NotificationManager {
        notificationManager
    }

    static func makePreviewHomeViewModel() -> HomeViewModel {
        HomeViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                      websiteDataStore: .nonPersistent(),
                      specialLinkHandler: specialLinkHandler,
                      notificationManager: notificationManager)
    }

    static func makePreviewServiceViewModel() -> ServiceViewModel {
        ServiceViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                         websiteDataStore: .nonPersistent(),
                         specialLinkHandler: specialLinkHandler,
                         notificationManager: notificationManager) {
            AppLog.viewModel.log("\(AppLog.logHeader()) Back to home called")
        }
    }

    #if IS_AMI_PRODUCTION || IS_AMI_PREPRODUCTION

        static func makeRootViewModel() -> RootViewModel<HomeViewModel> {
            let homeViewModel = HomeViewModel(rootUrl: Config.shared.BASE_URL,
                                              websiteDataStore: commonWebsiteDataStore,
                                              specialLinkHandler: specialLinkHandler,
                                              notificationManager: notificationManager)
            return RootViewModel(viewModel: homeViewModel,
                                 eventsSource: notificationEventObserverFeature.makeEventsSource())
        }

    #elseif IS_AMI_STAGING

        static func makeRootViewModel() -> RootViewModel<ReviewAppsListViewModel> {
            let reviewAppsListViewModel = ReviewAppsListViewModel(websiteDataStore: commonWebsiteDataStore,
                                                                  specialLinkHandler: specialLinkHandler,
                                                                  notificationManager: notificationManager)
            return RootViewModel(viewModel: reviewAppsListViewModel,
                                 eventsSource: notificationEventObserverFeature.makeEventsSource())
        }

        static func makePreviewReviewAppsListViewModel() -> ReviewAppsListViewModel {
            ReviewAppsListViewModel(websiteDataStore: .nonPersistent(),
                                    specialLinkHandler: specialLinkHandler,
                                    notificationManager: notificationManager)
        }

    #endif
}
