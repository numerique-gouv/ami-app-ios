//
//  NotificationManager.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 26/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import FirebaseMessaging
import Foundation
import SwiftUI
import UIKit
import WebKit

class NotificationManager: NSObject {
    struct DeviceRegisterInput: Encodable {
        let token: String
        let deviceId: String
        let platform: String = "ios"
        let deviceModel: String
        let appVersion: String

        private enum CodingKeys: String, CodingKey {
            case token = "fcm_token"
            case deviceId = "device_id"
            case platform
            case deviceModel = "model"
            case appVersion = "app_version"
        }
    }

    // The name of the cookie containing the authentication token.
    private static let AUTHENTICATION_COOKIE_NAME = "token"

    // The base URL (used in AppReview). Filled by calling `registerForRemoteNotifications(baseUrl: URL)`.
    // It is used to call the correct endpoint for device registration.
    private var baseUrl: URL?

    override init() {
        super.init()
    }

    func registerForRemoteNotifications(baseUrl: URL) async {
        self.baseUrl = baseUrl

        switch await notificationsAuthorizationStatus() {
        case .notDetermined:
            await requestNotificationsActivation()
        case .authorized, .ephemeral:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        case .denied, .provisional:
            break
        @unknown default:
            break
        }
    }

    // Get the auth token from shared cookie store.
    // Return nil if no toekn is found.
    private func getAuthToken() async -> String? {
        await SwiftUIWebView.sharedConfiguration
            .websiteDataStore
            .httpCookieStore
            .allCookies()
            .first(where: { $0.name == Self.AUTHENTICATION_COOKIE_NAME })?.value.replacingOccurrences(of: "\"", with: "")
    }

    private func registerDevice(token: String) async {
        guard let authToken = await getAuthToken() else {
            print("[NotificationManager]: ⚠️ No 'token' cookie found - cannot register device")
            return
        }

        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let deviceModel = await UIDevice.current.model
        let appVersion = AppBundle.version()

        print("[NotificationManager]: ✅ Registering device - fcmToken=\(token) deviceId=\(deviceId) model=\(deviceModel) platform=ios app_version=\(appVersion)")

        // prepare registration data.
        let registerInput = DeviceRegisterInput(token: token,
                                                deviceId: deviceId,
                                                deviceModel: deviceModel,
                                                appVersion: appVersion)

        // Make the API request
        await registerDevice(baseUrl: baseUrl!,
                             authenticationToken: authToken,
                             input: registerInput)
    }

    private func registerDevice(baseUrl: URL, authenticationToken: String, input: DeviceRegisterInput) async {
        let url = baseUrl.appendingPathComponent("/api/v1/users/registrations")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authenticationToken, forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(["subscription": input])

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    print("[NotificationManager]: ✅ Device registered successfully")
                } else {
                    print("[NotificationManager]: ⚠️ Device registration failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("[NotificationManager]: ❌ Device registration error: \(error.localizedDescription)")
        }
    }

    func openSettings() {
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

    func notificationsAuthorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    func requestNotificationsActivation() async {
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

    func requestPermission() {
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

    func resetAuthorization() {
        openSettings()
    }

    func isNotificationEnabled() async -> Bool {
        let status = await notificationsAuthorizationStatus()
        print("[NotificationManager]: Authorization status: \(status.rawValue) (\(status))")
        return status == .authorized
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        print("[NotificationManager]: Notification received while app is in foreground")
        print("[NotificationManager]: Notification title: \(notification.request.content.title)")
        print("[NotificationManager]: Notification body: \(notification.request.content.body)")
        print("[NotificationManager]: Notification data: \(userInfo)")

        // Display notification banner, play sound, and update badge even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        print("[NotificationManager]: User tapped notification")
        print("[NotificationManager]: Notification title: \(response.notification.request.content.title)")
        print("[NotificationManager]: Notification body: \(response.notification.request.content.body)")
        print("[NotificationManager]: Notification data: \(userInfo)")
        print("[NotificationManager]: Action identifier: \(response.actionIdentifier)")

        // Handle notification tap based on data
        // Example: navigate to specific screen, update UI, etc.
        if let customData = userInfo["customField"] as? String {
            print("[NotificationManager]: Custom data received: \(customData)")
            // TODO: Handle custom data (navigation, deep linking, etc.)
        }

        // Handle different action types
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print("[NotificationManager]: User tapped the notification banner")
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            print("[NotificationManager]: User dismissed the notification")
        }
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else {
            print("[NotificationManager]: FCM token is nil")
            return
        }

        // Execute `regsiterDevice` task in background job.
        Task(priority: .background) {
            await registerDevice(token: fcmToken)
        }
    }
}
