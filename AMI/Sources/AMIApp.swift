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
    @State private var openedFromNotification = false

    private static let notificationManager = NotificationManager()

    #if IS_AMI_STAGING
        let reviewAppViewModel: ReviewAppView.ViewModel
    #endif

    private static let homeViewModel = HomeView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: Self.notificationManager)

    init() {
        #if IS_AMI_STAGING
            reviewAppViewModel = ReviewAppView.ViewModel(notificationManager: Self.notificationManager)
        #endif
        delegate.notificationManager = Self.notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            #if IS_AMI_STAGING // && FALSE
                if openedFromNotification {
                    // TODO: should initialize home view model with review app backend url.
                    // Can I get it via the received notification?
                    HomeView(viewModel: Self.homeViewModel)
                } else {
                    ReviewAppView(viewModel: reviewAppViewModel)
                        .environmentObject(WebService())
                }
            #else
                HomeView(viewModel: homeViewModel)
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
        .onReceive(NotificationCenter.default.publisher(for: .pendingUrl)) { _ in
            openedFromNotification = true
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
