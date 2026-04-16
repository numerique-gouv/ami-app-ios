//
//  OnboardingViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 16/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

extension OnboardingView {
    @Observable
    class ViewModel: NSObject {
        enum Action {
            case activate
            case later
        }

        let applicationRootUrl: URL
        let notificationManager: NotificationManager
        var isPresentingOnboardingView = false

        init(applicationRootUrl: URL, notificationManager: NotificationManager) {
            self.applicationRootUrl = applicationRootUrl
            self.notificationManager = notificationManager
        }

        func processAction(_ action: Action) {
            switch action {
            case .activate:
                isPresentingOnboardingView = false
                registerForRemoteNotifications()
            case .later:
                isPresentingOnboardingView = false
            }
        }

        private func registerForRemoteNotifications() {
            Task {
                await notificationManager.registerForRemoteNotifications(baseUrl: applicationRootUrl)
            }
        }
    }
}
