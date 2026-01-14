import Foundation
import UserNotifications

enum NotificationHelper {
    static func requestPermission() {
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("NotificationHelper: Error requesting notification authorization: \(error)")
            } else {
                print("NotificationHelper: Notification authorization granted: \(granted)")
                if granted {
                    DispatchQueue.main.async {
                        InformationBannerManager.shared.showBanner(.validation, title: "Les notifications ont été activées")
                        WebViewManager.shared.goHome()
                    }
                }
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
