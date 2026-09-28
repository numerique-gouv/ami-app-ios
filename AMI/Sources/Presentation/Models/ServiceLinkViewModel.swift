//
//  ServiceLinkViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct ServiceLinkViewModel: Hashable {
    typealias DismissedAction = () -> Void

    private let url: URL
    private let dataStore: WKWebsiteDataStore
    private let notificationManager: NotificationManager

    let model: ServiceView.ViewModel

    init(url: URL, dataStore: WKWebsiteDataStore,
         notificationManager: NotificationManager,
         destinationViewDismissedAction: DismissedAction?) {
        self.url = url
        self.dataStore = dataStore
        self.notificationManager = notificationManager

        model = ServiceView.ViewModel(websiteDataStore: dataStore,
                                      rootUrl: url,
                                      notificationManager: notificationManager,
                                      backToHomeAction: destinationViewDismissedAction)
    }
}
