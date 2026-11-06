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
        // Init the root view distinct by environment:
        // - Staging:
        //   a ReviewAppsListView using a ReviewAppsListViewModel that catches
        //   all notification events and activates the corresponding review app
        //   or forwards the notification event to the review app if it is already active.
        // - PreProduction//Production:
        //   a RootView using a RootViewModel that catches all notification events
        //   but ignores any events not related to it (based on root Url).
        rootView = RootView(viewModel: DependencyContainer.makeRootViewModel())

        // Set default accent color for UIKit components.
        Color.setUIKitAccentColor()

        // Load Marianne fonts embedded in AMI Design System
        FontLoader.registerFonts()

        let notificationManager = DependencyContainer.makeNotificationManager()

        // Set the notificationManager to receive notification events.
        UNUserNotificationCenter.current().delegate = notificationManager

        // Set AppDelegate notificationManager for Firebase configuration.
        delegate.notificationManager = notificationManager
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
    }

    var body: some Scene {
        WindowGroup {
            mainContent
                // Define global view hierarchy accent color like this because this color is defined externaly.
                .tint(.dsfrAccentColor)
        }
    }
}
