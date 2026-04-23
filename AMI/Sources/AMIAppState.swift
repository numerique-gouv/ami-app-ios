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
    var offlineBannerId: UUID?

    var notificationTriggeredHomeViewModel: HomeView.ViewModel!
    // State to force refresh view when a notification is tapped by the user.
    var notificationActivatedHomeViewModelId: UUID?

    override init() {
        Self.defaultHomeViewModel = HomeView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: Self.notificationManager)
        notificationTriggeredHomeViewModel = Self.defaultHomeViewModel

        super.init()
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
