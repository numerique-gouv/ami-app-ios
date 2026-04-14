//
//  AMIApp.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

@main
struct AMIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var bannerManager = InformationBannerManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var offlineBannerId: UUID?

    private static let notificationManager = NotificationManager()

    @State private var notificationTriggeredHomeViewModel = Self.defaulthomeViewModel
    // State to force refresh view when a notification is tapped by the user.
    @State private var notificationActivatedHomeViewModelId: UUID?

    #if IS_AMI_STAGING
        let reviewAppViewModel: ReviewAppView.ViewModel
    #endif

    private static var defaulthomeViewModel = HomeView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: Self.notificationManager)

    init() {
        #if IS_AMI_STAGING
            reviewAppViewModel = ReviewAppView.ViewModel(notificationManager: Self.notificationManager)
        #endif

        // Set the notificationManager to receive notification events.
        UNUserNotificationCenter.current().delegate = Self.notificationManager

        // Set AppDelegate notificationManager for Firebase configuration.
        delegate.notificationManager = Self.notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            #if IS_AMI_STAGING
                if let notificationActivatedHomeViewModelId {
                    HomeView(viewModel: notificationTriggeredHomeViewModel)
                        .id(notificationActivatedHomeViewModelId)
                } else {
                    ReviewAppView(viewModel: reviewAppViewModel)
                        .environmentObject(WebService())
                }
            #else
                HomeView(viewModel: notificationTriggeredHomeViewModel)
                    .id(notificationActivatedHomeViewModelId)
            #endif

            VStack(spacing: 0) {
                ForEach(bannerManager.banners) { banner in
                    InformationBanner(data: banner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: bannerManager.banners.count)
        .environmentObject(networkMonitor)
        .onReceive(NotificationCenter.default.publisher(for: .pendingUrl)) { notification in
            notificationReceived(notification: notification)
        }
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                // Use deprecated version of `onChange` to handle iOS back to iOS 15.
                .onChange(of: networkMonitor.isConnected) { isConnected in
                    connectivityDidChange(isConnected: isConnected)
                }
        }
    }

    private func connectivityDidChange(isConnected: Bool) {
        print("Main App: received a network status change, isConnected=\(isConnected)")
        if isConnected {
            if let id = offlineBannerId {
                bannerManager.dismissBanner(id: id)
                offlineBannerId = nil
            }
        } else {
            offlineBannerId = bannerManager.showBanner(
                .warning,
                title: "Vous êtes hors ligne",
                content: "L'accès à certaines fonctionnalités est limité.",
                hasCloseIcon: false
            )
        }
    }

    private func notificationReceived(notification: Notification) {
        guard let appReviewUrl = notification.userInfo?[Notification.Name.pendingUrl] as? URL else {
            notificationTriggeredHomeViewModel = Self.defaulthomeViewModel
            notificationActivatedHomeViewModelId = nil
            return
        }
        print("[AmiApp] Notification Received: \(appReviewUrl)")

        notificationTriggeredHomeViewModel = HomeView.ViewModel(rootUrl: appReviewUrl.absoluteURL, notificationManager: Self.notificationManager)
        // Change view ID to force refresh.
        notificationActivatedHomeViewModelId = UUID()
    }
}
