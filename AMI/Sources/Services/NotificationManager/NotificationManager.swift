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
    /// The base URL (used in AppReview). Filled by calling `registerForRemoteNotifications(baseUrl: URL)`.
    /// It is used to call the correct endpoint for device registration.
    private var baseUrl: URL?
    /// userAuthenticationToken will be set after user logged in successfully.
    private var userAuthenticationToken: String?
    /// apnsToken will be set after allowing Push Notifications or Push Notification token renewal.
    private var apnsToken: String?

    /// How foreground notifications are displayed. Adjust as needed.
    private var foregroundPresentation: UNNotificationPresentationOptions = [.banner, .list, .sound]

    let dispatcher = NotificationDispatcher()

    override init() {
        super.init()
    }

    func setBaseUrl(_ url: URL) {
        baseUrl = url
        tryToRegisterDeviceForRemoteNotificationsToBackend()
    }

    func setUserAuthenticationToken(_ token: String?) {
        userAuthenticationToken = token
        tryToRegisterDeviceForRemoteNotificationsToBackend()
    }

    func setApnsToken(_ token: String?) {
        apnsToken = token
        tryToRegisterDeviceForRemoteNotificationsToBackend()
    }

    func registerForRemoteNotifications() async {
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

    private func tryToRegisterDeviceForRemoteNotificationsToBackend() {
        guard let baseUrl else {
            AppLog.service.warning("\(AppLog.logHeader(self)) Base url is not defined")
            return
        }

        guard let apnsToken else {
            AppLog.service.warning("\(AppLog.logHeader(self)) ApnsToken is not defined")
            return
        }

        guard let userAuthenticationToken else {
            AppLog.service.warning("\(AppLog.logHeader(self)) UserAuthenticationToken is not defined")
            return
        }

        /// Execute `registerDevice` task in background job.
        Task(priority: .background) {
            await RegisterDevice().registerDevice(baseUrl: baseUrl,
                                                  apnsToken: apnsToken,
                                                  userAuthenticationToken: userAuthenticationToken)
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Called when a push notification is delivered to the device while the application is in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        AppLog.service.notice(
            """
            \(AppLog.logHeader(self)) Notification received while app is in foreground:
            \tNotification title: \(notification.request.content.title)
            \t\(notification.request.content.body)
            \tNotification data: \(userInfo)
            """
        )

        /// Disaptch notification to subscribers.
        dispatcher.publish(NotificationEvent(request: notification.request,
                                             date: notification.date,
                                             source: .foreground))

        /// Display notification banner, play sound, and update badge even when app is open
        completionHandler(foregroundPresentation)
    }

    /// Called when a push notification is tapped by the user when the application is in background.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        AppLog.service.notice(
            """
                    \(AppLog.logHeader(self)) User tapped notification:
                    \tNotification title: \(response.notification.request.content.title)")
                    \tNotification body: \(response.notification.request.content.body)")
                    \tNotification data: \(userInfo)")
                    \tAction identifier: \(response.actionIdentifier)
            """
        )

        /// Handle different action types
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            AppLog.service.notice("\(AppLog.logHeader(self)) User tapped the notification banner, navigating to the notifications page")

            /// Handle reception of notification (review app for instance)
//            if let appUrlString = userInfo["app_url"] as? String,
//               let targetApplicationUrl = URL(string: appUrlString) {
//                handleIncomingNotificationUrl(url: targetApplicationUrl)
//            }
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            AppLog.service.notice("\(AppLog.logHeader(self)) User dismissed the notification")
        }

        /// Disaptch notification to subscribers.
        dispatcher.publish(NotificationEvent(request: response.notification.request,
                                             date: response.notification.date,
                                             source: .userResponse(actionIdentifier: response.actionIdentifier)))

        /// Call completion handler.
        completionHandler()
    }

    /// Call from the AppDelegate's didReceiveRemoteNotification for silent pushes.
    func publishSilentPush(userInfo: [AnyHashable: Any]) {
        dispatcher.publishSilentPush(userInfo: userInfo)
    }
}

extension NotificationManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else {
            AppLog.service.warning("\(AppLog.logHeader(self)) FCM token is nil")
            return
        }

        AppLog.service.notice("\(AppLog.logHeader(self)) didReceiveRegistrationToken: \(fcmToken, privacy: .private)")
    }
}
