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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
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
            NavigationStack {
                #if IS_AMI_STAGING
                    if let notificationActivatedHomeViewModelId = appState.notificationActivatedHomeViewModelId {
                        HomeView(viewModel: appState.notificationTriggeredHomeViewModel)
                            .id(notificationActivatedHomeViewModelId)
                    } else {
                        ReviewAppView(viewModel: ReviewAppView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: AMIAppState.notificationManager))
                            .environmentObject(WebService())
                    }
                #elseif IS_AMI_PRODUCTION
                    HomeView(viewModel: AMIAppState.defaultHomeViewModel)
                        .id(appState.notificationActivatedHomeViewModelId ?? UUID())
                #else
                    EmptyView()
                #endif
            }
            // On SwiftUI, removing the defaut Navigation Back button disable the Swipe Back gesture.
            // We reactivate it via trhe underlying UIKit UINavigationController.
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
        }
    }
}
