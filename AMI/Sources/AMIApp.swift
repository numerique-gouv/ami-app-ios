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
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Bindable var appState = AMIAppState()

    init() {
        // Set the notificationManager to receive notification events.
        UNUserNotificationCenter.current().delegate = AMIAppState.notificationManager

        // Set AppDelegate notificationManager for Firebase configuration.
        delegate.notificationManager = AMIAppState.notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            #if IS_AMI_STAGING
                if let notificationActivatedHomeViewModelId = appState.notificationActivatedHomeViewModelId {
                    HomeView(viewModel: appState.notificationTriggeredHomeViewModel)
                        .id(notificationActivatedHomeViewModelId)
                } else {
                    ReviewAppView(viewModel: ReviewAppView.ViewModel(notificationManager: AMIAppState.notificationManager))
                        .environmentObject(WebService())
                }
            #else
                HomeView(viewModel: notificationTriggeredHomeViewModel)
                    .id(notificationActivatedHomeViewModelId)
            #endif

            VStack(spacing: 0) {
                ForEach(appState.bannerManager.banners) { banner in
                    InformationBanner(data: banner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .environmentObject(networkMonitor)
        .animation(.easeInOut(duration: 0.3), value: appState.bannerManager.banners.count)
        .onReceive(NotificationCenter.default.publisher(for: .pendingUrl)) { notification in
            appState.notificationReceived(notification: notification)
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
}
