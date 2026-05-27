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
        let notificationManager: NotificationManager
        var reviewApps: [ReviewApp] = []

        private var viewModels = [URL: AnyObject]()

        init(notificationManager: NotificationManager) {
            self.notificationManager = notificationManager
            super.init()

            Task {
                try? await self.fetchReviewApps()
            }
        }

        func reviewModel(for url: URL) -> AnyObject {
            guard let viewModel = viewModels[url] else {
                let viewModel = HomeView.ViewModel(rootUrl: url, notificationManager: notificationManager)
                viewModels[url] = viewModel
                return viewModel
            }
            return viewModel
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
