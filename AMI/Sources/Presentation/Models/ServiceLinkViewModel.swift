//
//  ServiceLinkViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
struct ServiceLinkViewModel {
    typealias DismissedAction = () -> Void

    private let destinationUrl: URL
    private let dataStore: WKWebsiteDataStore
    private let sourceUrl: URL?
    private let specialLinkHandler: any SpecialLinkProtocol
    private let notificationManager: NotificationManager

    let model: ServiceViewModel

    init(destinationUrl: URL,
         dataStore: WKWebsiteDataStore,
         sourceUrl: URL? = nil,
         specialLinkHandler: any SpecialLinkProtocol,
         notificationManager: NotificationManager,
         destinationViewDismissedAction: DismissedAction?) {
        self.destinationUrl = destinationUrl
        self.dataStore = dataStore
        self.sourceUrl = sourceUrl
        self.specialLinkHandler = specialLinkHandler
        self.notificationManager = notificationManager

        model = ServiceViewModel(rootUrl: destinationUrl,
                                 websiteDataStore: dataStore,
                                 refererUrl: sourceUrl,
                                 specialLinkHandler: specialLinkHandler,
                                 notificationManager: notificationManager,
                                 backToHomeAction: destinationViewDismissedAction)
    }
}

extension ServiceLinkViewModel: @MainActor Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.destinationUrl == rhs.destinationUrl && lhs.dataStore == rhs.dataStore && lhs.sourceUrl == rhs.sourceUrl
    }
}

extension ServiceLinkViewModel: @MainActor Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(destinationUrl)
        hasher.combine(sourceUrl)
        hasher.combine(dataStore)
    }
}
