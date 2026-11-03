//
//  ReviewApp-ViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension ReviewAppView {
    @MainActor
    @Observable
    class ViewModel: NSObject {
        let rootUrl = Config.shared.BASE_URL // This root URL is always the same. No need to make it a parameter.
        let websiteDataStore: WKWebsiteDataStore
        let specialLinkHandler: any SpecialLinkProtocol
        let notificationManager: NotificationManager
        var reviewApps: [ReviewApp] = []

        var selectedReviewAppViewModel: HomeView.ViewModel?

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
            guard let url = URL(string: reviewApp.url) else {
                selectedReviewAppViewModel = nil
                return
            }
            selectedReviewAppViewModel = HomeView.ViewModel(rootUrl: url,
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

        func notificationReceived(notification: Notification) {
            guard let appReviewUrl = notification.userInfo?[Notification.Name.pendingUrl] as? URL,
                  let reviewApp = reviewApps.first(where: { URL(string: $0.url)?.host() == appReviewUrl.host() }) else {
                selectedReviewAppViewModel = nil
                return
            }

            AppLog.app.notice("\(AppLog.logHeader(self)) Notification Received for review app: \(reviewApp)")

            selectedReviewAppViewModel = nil
            Task { @MainActor in
                // Wait for the ReviewApp list to display.
                try? await Task.sleep(for: .seconds(0.5))
                selectReviewApp(reviewApp: reviewApp)
            }
        }
    }
}
