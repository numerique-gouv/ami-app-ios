import Foundation
import UIKit
import UserNotifications

enum NotificationHelper {
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

    static func requestNotificationsActivation() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error {
                print("NotificationHelper: Error requesting notification authorization: \(error)")
            } else {
                print("NotificationHelper: Notification authorization granted: \(granted)")
                if granted {
                    Task { @MainActor in
                        InformationBannerManager.shared.showBanner(.validation, title: "Les notifications ont été activées")
                        WebViewManager.shared.goHome()
                    }
                }
            }
        }
    }

    static func requestPermission() {
        Task {
            switch await notificationsAuthorizationStatus() {
            case .denied:
                print("NotificationHelper: Permission denied - opening settings")
                openSettings()
            case .notDetermined:
                print("NotificationHelper: Permission not determined, trying to open the OS popup")
                requestNotificationsActivation()
            default:
                print("NotificationHelper: Permission already granted or provisional")
            }
        }
    }

    static func resetAuthorization() {
        openSettings()
    }
    
    static func isNotificationEnabled() async -> Bool {
        let status = await notificationsAuthorizationStatus()
        print("NotificationHelper: Authorization status: \(status.rawValue) (\(status))")
        return status == .authorized
    }
}
