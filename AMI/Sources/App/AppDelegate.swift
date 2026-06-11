//
//  AppDelegate.swift
//  AMI
//
//  Created by Aline Bonnet on 17/11/2025.
//

import FirebaseCore
import FirebaseMessaging
import SwiftUI

extension Notification.Name {
    static let pendingUrl = Notification.Name("pendingUrl")
}

class AppDelegate: NSObject, UIApplicationDelegate {
    // The notificationManager is set by AMIApp.
    var notificationManager: NotificationManager? {
        didSet {
            Task {
                // If Firebase get an existing Apns token, and NotificationManager doesn't have one, set it into NotificationManager.
                if let currentApnsToken = try? await Messaging.messaging().token() {
                    notificationManager?.setApnsToken(currentApnsToken)
                }
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Setup application
        setupFirebase()

        return true
    }

    private func setupFirebase() {
        let firebaseConfigFilename = "GoogleService-Info"

        guard let filePath = AppBundle.path(for: firebaseConfigFilename, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Could not load Firebase config file: \(firebaseConfigFilename).plist")
        }

        FirebaseApp.configure(options: options)
        #if IS_AMI_STAGING
            AppLog.app.notice("\(AppLog.logHeader(self)) Firebase configured with \(firebaseConfigFilename).plist for environment: STAGING")
        #else
            AppLog.app.notice("\(type(of: self)) Firebase configured with \(firebaseConfigFilename).plist for environment: PRODUCTION")
        #endif

        // Set Messaging Delegate to receive FCM token updates
        Messaging.messaging().delegate = notificationManager
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppLog.app.notice("\(AppLog.logHeader(self)) Received APNS device token")

        // Pass APNS token to Firebase for proper notification delivery
        // Messaging delegate (NotificationManager) method `messaging:didReceiveRegistrationToken:` will be called only if apnsToken did change from previous one.
        Messaging.messaging().apnsToken = deviceToken

        // So, don't rely on `messaging:didReceiveRegistrationToken` to register device to our backend.
        Task {
            if let token = try? await Messaging.messaging().token() {
                // Setting Apns token will trigger a backend registration if all needed data is available.
                notificationManager?.setApnsToken(token)
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLog.app.notice("\(AppLog.logHeader(self)) Failed to register for remote notifications: \(error)")
        AppLog.app.notice("\(AppLog.logHeader(self)) This is normal in the simulator - FCM will still work for testing")
    }
}
