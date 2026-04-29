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
    // The base URL (used in AppReview). Filled by calling `registerForRemoteNotifications(baseUrl: URL)`.
    // It is used to call the correct endpoint for device registration.
    private var baseUrl: URL?
    // userAuthenticationToken will be set after user logged in successfully.
    var userAuthenticationToken: String?

    override init() {
        super.init()
    }

    func registerForRemoteNotifications(baseUrl: URL) async {
        self.baseUrl = baseUrl

        switch await NotificationStatus.notificationsAuthorizationStatus() {
        case .notDetermined:
            await NotificationStatus.requestNotificationsActivation()
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

    func registerDeviceForRemoteNotificationsToBackend(apnsToken: String) {
        guard let baseUrl else {
            print("[NotificationManager] registerDeviceForRemoteNotificationsToBackend : Base url is not defined")
            return
        }

        guard let userAuthenticationToken else {
            print("[NotificationManager] registerDeviceForRemoteNotificationsToBackend : userAuthenticationToken is not defined")
            return
        }

        // Execute `regsiterDevice` task in background job.
        Task(priority: .background) {
            await RegisterDevice().registerDevice(baseUrl: baseUrl,
                                                  apnsToken: apnsToken,
                                                  userAuthenticationToken: userAuthenticationToken)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    // Called when a push notification is delivered to the device while the application is in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        print("[NotificationManager] Notification received while app is in foreground")
        print("[NotificationManager] Notification title: \(notification.request.content.title)")
        print("[NotificationManager] Notification body: \(notification.request.content.body)")
        print("[NotificationManager] Notification data: \(userInfo)")

        // Display notification banner, play sound, and update badge even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    // Called when a push notification is tapped by the user when the application is in background.
    // Annotate with @MainActor else when called, the application is in background state and this will trigger a crash: `NSInternalInconsistencyException', reason: 'Call must be made on main thread'`
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        print("[NotificationManager] User tapped notification")
        print("[NotificationManager] Notification title: \(response.notification.request.content.title)")
        print("[NotificationManager] Notification body: \(response.notification.request.content.body)")
        print("[NotificationManager] Notification data: \(userInfo)")
        print("[NotificationManager] Action identifier: \(response.actionIdentifier)")

        // Handle different action types
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print("[NotificationManager] User tapped the notification banner, navigating to the notifications page")

            // Handle reception of notification (review app for instance)
            if let appUrlString = userInfo["app_url"] as? String,
               let targetApplicationUrl = URL(string: appUrlString) {
                handleIncomingNotificationUrl(url: targetApplicationUrl)
            }
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            print("[NotificationManager] User dismissed the notification")
        }
    }

    private func handleIncomingNotificationUrl(url: URL) {
        print("[NotificationManager] app_url received: \(url)")
        guard let notificationsURL = URL(string: "/#/notifications", relativeTo: url) else {
            return
        }

        // Use NotificationCenter rather than callback to be sure the notification is treated on the main UI thread.
        let notification = Notification(name: Notification.Name.pendingUrl, object: nil, userInfo: [Notification.Name.pendingUrl: notificationsURL])
        NotificationCenter.default.post(notification)
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else {
            print("[NotificationManager] FCM token is nil")
            return
        }

        #if DEBUG
            print("[NotificationManager] didReceiveRegistrationToken: \(fcmToken)")
        #endif
    }
}
