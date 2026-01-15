import Foundation
import UIKit
import UserNotifications

enum NotificationHelper {
    static func openSettings() {
        Task { @MainActor in
            let urlString: String
            if #available(iOS 16.0, *) {
                urlString = UIApplication.openNotificationSettingsURLString
            } else {
                urlString = UIApplication.openSettingsURLString
            }
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }

    static func checkNotificationsPermission() async -> UNNotificationSettings {
        await UNUserNotificationCenter.current().notificationSettings()
    }

    static func requestNotificationsActivation() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
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
            let settings = await checkNotificationsPermission()
            switch settings.authorizationStatus {
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

    static func isNotificationEnabled() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        let status = settings.authorizationStatus
        print("NotificationHelper: Authorization status: \(status.rawValue) (\(status))")
        return status == .authorized
    }
}
