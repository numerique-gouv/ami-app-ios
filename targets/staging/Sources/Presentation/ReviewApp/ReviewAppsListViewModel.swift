//
//  ReviewAppsListViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
@Observable
class ReviewAppsListViewModel: NSObject {
    let rootUrl = Config.shared.BASE_URL // This root URL is always the same. No need to make it a parameter.
    let websiteDataStore: WKWebsiteDataStore
    let specialLinkHandler: any SpecialLinkProtocol
    let notificationManager: NotificationManager
    var reviewApps: [ReviewApp] = []

    var selectedReviewAppViewModel: HomeViewModel?

    init(websiteDataStore: WKWebsiteDataStore,
         specialLinkHandler: any SpecialLinkProtocol,
         notificationManager: NotificationManager) {
        self.websiteDataStore = websiteDataStore
        self.specialLinkHandler = specialLinkHandler
        self.notificationManager = notificationManager
        super.init()

        Task {
            try? await self.fetchReviewApps()
        }
    }

    func selectReviewApp(reviewApp: ReviewApp) {
        selectedReviewAppViewModel = HomeViewModel(rootUrl: reviewApp.url,
                                                   websiteDataStore: websiteDataStore,
                                                   specialLinkHandler: specialLinkHandler,
                                                   notificationManager: notificationManager)
    }

    func fetchReviewApps() async throws {
        let url = rootUrl.appending(path: "dev-utils/review-apps")

        let request = URLRequest(url: url)

        let (data, _) = try await URLSession.shared.data(for: request)
        let decoder = JSONDecoder()
        let body = try decoder.decode([ReviewApp].self, from: data)
        reviewApps = body
    }
}

extension ReviewAppsListViewModel: NotificationEventHandler {
    /// The action called by the Notification Disaptcher when a NotificationEvent is received.
    func handleReceivedNotificationEvent(event: NotificationEvent) async {
        // Only handle user tapped notification.
        guard case .userResponse = event.source else {
            return
        }

        // Call action only if the host of the application URL of the notification payload matches the base domain.
        if let targetApplicationUrl = try? event.decodePayload(as: NotificationEventPayload.self)?.applicationUrl,
           // Get the targeted review app.
           let reviewAppModel = await reviewApps.first(where: { $0.url.host() == targetApplicationUrl.host() }) {
            // Activate the target review app if it is not the active one.
            if await reviewAppModel.url != selectedReviewAppViewModel?.webViewViewModel.rootUrl {
                Task { @MainActor in
                    selectedReviewAppViewModel = nil
                    // wait for the pop animation to finish.
                    try? await Task.sleep(for: .milliseconds(400))
                    selectReviewApp(reviewApp: reviewAppModel)
                    // wait for the page to load before navigating to Notifications screen.
                    try? await Task.sleep(for: .milliseconds(1000))
                    selectedReviewAppViewModel?.handleIncomingUrl(url: targetApplicationUrl)
                }
            } else {
                await selectedReviewAppViewModel?.handleIncomingUrl(url: targetApplicationUrl)
            }
        } else {
            AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unable to handle incoming notification event:\t\(event)")
        }
    }
}
