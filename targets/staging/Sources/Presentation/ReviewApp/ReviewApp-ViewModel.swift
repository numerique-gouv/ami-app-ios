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
    @Observable
    class ViewModel: NSObject {
        let rootUrl = Config.shared.BASE_URL // This root URL is always the same. No need to make it a parameter.
        let websiteDataStore: WKWebsiteDataStore
        let notificationManager: NotificationManager
        var reviewApps: [ReviewApp] = []

        var selectedReviewAppViewModel: HomeView.ViewModel?

        init(websiteDataStore: WKWebsiteDataStore, notificationManager: NotificationManager) {
            self.websiteDataStore = websiteDataStore
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
            selectedReviewAppViewModel = HomeView.ViewModel(rootUrl: url, websiteDataStore: websiteDataStore, notificationManager: notificationManager)
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
}
