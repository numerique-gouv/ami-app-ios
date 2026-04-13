//
//  NotificationStatus.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 07/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit

enum NotificationStatus {
    static func openSettings() {
        Task { @MainActor in
            let urlString =
                if #available(iOS 16.0, *) {
                    UIApplication.openNotificationSettingsURLString
                } else {
                    UIApplication.openSettingsURLString
                }
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }

    static func notificationsAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func requestNotificationsActivation() async {
        do {
            if try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
                print("[NotificationManager]: Notification authorization granted: \(true)")
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    InformationBannerManager.shared.showBanner(.validation, title: "Les notifications ont été activées")
                }
            }
        } catch {
            print("[NotificationManager]: Error requesting notification authorization: \(error)")
        }
    }

    static func requestPermission() {
        Task {
            switch await notificationsAuthorizationStatus() {
            case .denied:
                print("[NotificationManager]: Permission denied - opening settings")
                openSettings()
            case .notDetermined:
                print("[NotificationManager]: Permission not determined, trying to open the OS popup")
                await requestNotificationsActivation()
            default:
                print("[NotificationManager]: Permission already granted or provisional")
            }
        }
    }

    static func resetAuthorization() {
        openSettings()
    }

    static func isNotificationEnabled() async -> Bool {
        let status = await notificationsAuthorizationStatus()
        print("[NotificationManager]: Authorization status: \(status.rawValue) (\(status))")
        return status == .authorized
    }
}
