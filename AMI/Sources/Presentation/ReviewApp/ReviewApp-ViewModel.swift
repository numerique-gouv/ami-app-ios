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
        let notificationManager: NotificationManager

        private var viewModels = [URL: AnyObject]()

        init(notificationManager: NotificationManager) {
            self.notificationManager = notificationManager
        }

        func reviewModel(for url: URL) -> AnyObject {
            guard let viewModel = viewModels[url] else {
                let viewModel = HomeView.ViewModel(rootUrl: url, notificationManager: notificationManager)
                viewModels[url] = viewModel
                return viewModel
            }
            return viewModel
        }

        deinit {
            print("deinit")
        }
    }
}
