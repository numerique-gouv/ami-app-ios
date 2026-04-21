//
//  AMIApp.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@main
struct AMIApp: App {
    // Static properties
    private static let notificationManager = NotificationManager()
    private static var defaultHomeViewModel = HomeView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: Self.notificationManager)

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var bannerManager = InformationBannerManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @State private var offlineBannerId: UUID?

    @State private var notificationTriggeredHomeViewModel = Self.defaultHomeViewModel
    // State to force refresh view when a notification is tapped by the user.
    @State private var notificationActivatedHomeViewModelId: UUID?

    init() {
        // Set the notificationManager to receive notification events.
        UNUserNotificationCenter.current().delegate = Self.notificationManager

        // Set AppDelegate notificationManager for Firebase configuration.
        delegate.notificationManager = Self.notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                #if IS_AMI_STAGING
                    if let notificationActivatedHomeViewModelId {
                        HomeView(viewModel: notificationTriggeredHomeViewModel)
                            .id(notificationActivatedHomeViewModelId)
                    } else {
                        ReviewAppView(viewModel: ReviewAppView.ViewModel(notificationManager: Self.notificationManager))
                            .environmentObject(WebService())
                    }
                #elseif IS_AMI_PRODUCTION
                    HomeView(viewModel: Self.defaultHomeViewModel)
                        .id(notificationActivatedHomeViewModelId)
                #else
                    EmptyView()
                #endif

                VStack(spacing: 0) {
                    ForEach(bannerManager.banners) { banner in
                        InformationBanner(data: banner)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            // On SwiftUI, removing the defaut Navigation Back button disable the Swipe Back gesture.
            // We reactivate it via trhe underlying UIKit UINavigationController.
            .introspect(.navigationStack, on: .iOS(.v16...)) { view in
                view.interactivePopGestureRecognizer?.isEnabled = true
                view.interactivePopGestureRecognizer?.delegate = nil
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
            notificationTriggeredHomeViewModel = Self.defaultHomeViewModel
            notificationActivatedHomeViewModelId = nil
            return
        }
        print("[AmiApp] Notification Received: \(appReviewUrl)")

        notificationTriggeredHomeViewModel = HomeView.ViewModel(rootUrl: appReviewUrl.absoluteURL, notificationManager: Self.notificationManager)
        // Change view ID to force refresh.
        notificationActivatedHomeViewModelId = UUID()
    }
}
