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

    let notificationManager = NotificationManager()

    #if IS_AMI_STAGING
        let reviewAppViewModel: ReviewAppView.ViewModel
    #endif

    init() {
        #if IS_AMI_STAGING
            reviewAppViewModel = ReviewAppView.ViewModel(notificationManager: notificationManager)
        #endif
        delegate.notificationManager = notificationManager
    }

    @ViewBuilder
    private var mainContent: some View {
        ZStack(alignment: .top) {
            #if IS_AMI_STAGING // && FALSE
                ReviewAppView(viewModel: reviewAppViewModel)
                    .environmentObject(WebService())
            #else
                HomeView(initialUrl: Config.shared.BASE_URL)
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
