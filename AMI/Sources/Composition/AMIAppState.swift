//
//  AMIAppState.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 21/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import Observation
import WebKit

@Observable
@MainActor
class AMIAppState: NSObject {
    var bannerManager = InformationBannerManager.shared
    private var offlineBannerId: UUID?

    private let networkMonitor = NetworkMonitor()

    #if IS_AMI_STAGING
        let reviewAppViewModel = DependencyContainer.makePreviewReviewAppViewModel()
    #else
        let mainViewModel = DependencyContainer.makeHomeViewModel()
    #endif

    override init() {
        super.init()

        networkMonitor.eventReceiver = { connectionState in
            Task { @MainActor in
                self.connectivityDidChange(state: connectionState)
            }
        }
    }

    func connectivityDidChange(state: NetworkMonitor.EventType) {
        AppLog.app.notice("\(AppLog.logHeader(self)) Received a network status change, isConnected=\(state == .connected ? "Connected" : "Not connected")")
        switch state {
        case .connected:
            if let id = offlineBannerId {
                bannerManager.dismissBanner(id: id)
                offlineBannerId = nil
            }
        case .notConnected:
            // Check no previous offline banner is already present.
            guard offlineBannerId == nil else {
                return
            }

            offlineBannerId = bannerManager.showBanner(
                .warning,
                title: "Vous êtes hors ligne",
                content: "L'accès à certaines fonctionnalités est limité.",
                hasCloseIcon: false
            )
        }
    }
}
