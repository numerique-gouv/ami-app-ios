//
//  AMIAppState.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 21/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import Observation

@Observable
class AMIAppState: NSObject {
    static let notificationManager = NotificationManager()
    static var defaultHomeViewModel: HomeView.ViewModel!

    var bannerManager = InformationBannerManager.shared
    var networkMonitor = NetworkMonitor()
    var offlineBannerId: UUID?

    var notificationTriggeredHomeViewModel: HomeView.ViewModel!
    // State to force refresh view when a notification is tapped by the user.
    var notificationActivatedHomeViewModelId: UUID?

    override init() {
        Self.defaultHomeViewModel = HomeView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: Self.notificationManager)
        notificationTriggeredHomeViewModel = Self.defaultHomeViewModel

        super.init()

        networkMonitor.eventReceiver = { connectionState in
            Task { @MainActor in
                self.connectivityDidChange(state: connectionState)
            }
        }
    }

    func connectivityDidChange(state: NetworkMonitor.EventType) {
        print("Main App: received a network status change, isConnected=\(state == .connected ? "Connected" : "Not connected")")
        switch state {
        case .connected:
            if let id = offlineBannerId {
                bannerManager.dismissBanner(id: id)
                offlineBannerId = nil
            }
        case .notConnected:
            // Check no previous offline banner is already present.
            guard offlineBannerId == nil else {
                return
            }

            offlineBannerId = bannerManager.showBanner(
                .warning,
                title: "Vous êtes hors ligne",
                content: "L'accès à certaines fonctionnalités est limité.",
                hasCloseIcon: false
            )
        }
    }

    func notificationReceived(notification: Notification) {
        guard let appReviewUrl = notification.userInfo?[Notification.Name.pendingUrl] as? URL else {
            notificationTriggeredHomeViewModel = Self.defaultHomeViewModel
            notificationActivatedHomeViewModelId = nil
            return
        }
        print("[AmiApp] Notification Received: \(appReviewUrl)")

        notificationTriggeredHomeViewModel = HomeView.ViewModel(rootUrl: appReviewUrl.absoluteURL, notificationManager: Self.notificationManager)
        // Change view ID to force refresh.
        notificationActivatedHomeViewModelId = UUID()
    }
}
