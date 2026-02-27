//
//  AppDelegate.swift
//  AMI
//
//  Created by Aline Bonnet on 17/11/2025.
//

import FirebaseCore
import FirebaseMessaging
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    // The notificationManager is set by AMIApp.
    var notificationManager: NotificationManager?

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
            print("Firebase configured with \(firebaseConfigFilename).plist for environment: STAGING")
        #else
            print("Firebase configured with \(firebaseConfigFilename).plist for environment: PRODUCTION")
        #endif

        // Set Messaging Delegate to receive FCM token updates
        Messaging.messaging().delegate = notificationManager
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("[AppDelegate]: Received APNS device token")

        // Pass APNS token to Firebase for proper notification delivery
        // Messaging delegate (NotificationManager) method `messaging:didReceiveRegistrationToken:` will be called only if apnsToken did change from previous one.
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[AppDelegate]: Failed to register for remote notifications: \(error)")
        print("[AppDelegate]: This is normal in the simulator - FCM will still work for testing")
    }
}
