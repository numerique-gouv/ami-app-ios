//
//  AMIApp.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import AmiDesignSystem
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@main
struct AMIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Bindable var appState = DependencyContainer.appState
    @State var rootView: RootView

    init() {
        rootView = RootView(viewModel: RootView.ViewModel())

        // Set default accent color for UIKit components.
        Color.setUIKitAccentColor()

        // Load Marianne fonts embedded in AMI Design System
        FontLoader.registerFonts()

        // Set the notificationManager to receive notification events.
        UNUserNotificationCenter.current().delegate = DependencyContainer.notificationManager

        // Set AppDelegate notificationManager for Firebase configuration.
        delegate.notificationManager = DependencyContainer.notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            NavigationStack {
                rootView
            }
            // On SwiftUI, removing the defaut Navigation Back button disable the Swipe Back gesture.
            // We reactivate it via the underlying UIKit UINavigationController.
            .introspect(.navigationStack, on: .iOS(.v16...)) { view in
                view.interactivePopGestureRecognizer?.isEnabled = true
                view.interactivePopGestureRecognizer?.delegate = nil
            }

            // Banners container
            VStack(spacing: 0) {
                ForEach(appState.bannerManager.banners) { banner in
                    InformationBanner(data: banner)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.bannerManager.banners.count)
        .onReceive(NotificationCenter.default.publisher(for: .pendingUrl)) { notification in
            appState.notificationReceived(notification: notification)
        }
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                // Define global view hierarchy accent color like this because this color is defined externaly.
                .tint(.dsfrAccentColor)
        }
    }
}
