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
                AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Notification authorization granted: \(true)")
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    InformationBannerManager.shared.showBanner(.validation, title: "Les notifications ont été activées")
                }
            }
        } catch {
            AppLog.service.error("\(AppLog.logHeader(caller: self, function: #function)) Error requesting notification authorization: \(error)")
        }
    }

    static func requestPermission() {
        Task {
            switch await notificationsAuthorizationStatus() {
            case .denied:
                AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Permission denied - opening settings")
                openSettings()
            case .notDetermined:
                AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Permission not determined, trying to open the OS popup")
                await requestNotificationsActivation()
            default:
                AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Permission already granted or provisional")
            }
        }
    }

    static func resetAuthorization() {
        openSettings()
    }

    static func isNotificationEnabled() async -> Bool {
        let status = await notificationsAuthorizationStatus()
        AppLog.service.notice("\(AppLog.logHeader(caller: self, function: #function)) Authorization status: \(status.rawValue) (\(status))")
        return status == .authorized
    }
}

extension UNAuthorizationStatus: @retroactive CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined: "notDetermined"
        case .denied: "denied"
        case .authorized: "authorized"
        case .provisional: "provisional"
        case .ephemeral: "ephemeral"
        @unknown default: "Unknown UNAuthorizationStatus"
        }
    }
}
