//
//  AppDelegate.swift
//  AMI
//
//  Created by Aline Bonnet on 17/11/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseMessaging

extension Notification.Name {
    static let fcmTokenRefreshed = Notification.Name("fcmTokenRefreshed")
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Determine which GoogleService-Info plist to use based on environment
        let environment = Bundle.main.object(forInfoDictionaryKey: "CURRENT_ENV") as? String ?? "PROD"
        let fileName = environment == "STAGING" ? "GoogleService-Info-Staging" : "GoogleService-Info-Prod"

        guard let filePath = Bundle.main.path(forResource: fileName, ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: filePath) else {
            fatalError("Could not load Firebase config file: \(fileName).plist")
        }

        FirebaseApp.configure(options: options)
        print("Firebase configured with \(fileName).plist for environment: \(environment)")

        // Set MessagingDelegate to receive FCM token updates
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if let error = error {
                print("AppDelegate: Error requesting notification authorization: \(error)")
            } else {
                print("AppDelegate: Notification authorization granted: \(granted)")
            }
        }

        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("AppDelegate: Received APNS device token")

        // Pass APNS token to Firebase for proper notification delivery
        Messaging.messaging().apnsToken = deviceToken

        // Fetch FCM token after APNS token is set
        fetchFCMToken()
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("AppDelegate: Failed to register for remote notifications: \(error)")
        print("AppDelegate: This is normal in the simulator - FCM will still work for testing")

        // Even if APNS fails (simulator), try to get FCM token for testing
        fetchFCMToken()
    }

    private func storeAndNotifyFCMToken(_ token: String) {
        print("AppDelegate: storing and notifying FCM token: \(token)")
        // Store token in UserDefaults for WebView to access
        UserDefaults.standard.set(token, forKey: "fcmToken")

        // Notify observers that the token is available
        NotificationCenter.default.post(name: .fcmTokenRefreshed, object: nil, userInfo: ["token": token])
    }

    private func fetchFCMToken() {
        Task {
            do {
                let token = try await Messaging.messaging().token()
                print("AppDelegate: FCM token retrieved successfully!")
                storeAndNotifyFCMToken(token)
            } catch {
                print("AppDelegate: Error fetching FCM token: \(error)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo

        print("AppDelegate: Notification received while app is in foreground")
        print("AppDelegate: Notification title: \(notification.request.content.title)")
        print("AppDelegate: Notification body: \(notification.request.content.body)")
        print("AppDelegate: Notification data: \(userInfo)")

        // Display notification banner, play sound, and update badge even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo

        print("AppDelegate: User tapped notification")
        print("AppDelegate: Notification title: \(response.notification.request.content.title)")
        print("AppDelegate: Notification body: \(response.notification.request.content.body)")
        print("AppDelegate: Notification data: \(userInfo)")
        print("AppDelegate: Action identifier: \(response.actionIdentifier)")

        // Handle notification tap based on data
        // Example: navigate to specific screen, update UI, etc.
        if let customData = userInfo["customField"] as? String {
            print("AppDelegate: Custom data received: \(customData)")
            // TODO: Handle custom data (navigation, deep linking, etc.)
        }

        // Handle different action types
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            print("AppDelegate: User tapped the notification banner")
        } else if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            print("AppDelegate: User dismissed the notification")
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let token = fcmToken {
            print("AppDelegate: FCM token received/refreshed")
            storeAndNotifyFCMToken(token)
        } else {
            print("AppDelegate: FCM token is nil")
        }
    }
}
