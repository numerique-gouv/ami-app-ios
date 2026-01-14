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

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                if Config.shared.CURRENT_ENV == "STAGING" {
                    ReviewAppView().environmentObject(WebService())
                } else {
                    HomeView()
                }

                VStack(spacing: 0) {
                    ForEach(bannerManager.banners) { banner in
                        InformationBanner(data: banner)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: bannerManager.banners.count)
        }
    }
}
