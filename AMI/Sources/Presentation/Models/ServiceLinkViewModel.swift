//
//  ServiceLinkViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct ServiceLinkViewModel {
    typealias DismissedAction = () -> Void

    private let sourceUrl: URL?
    private let destinationUrl: URL
    private let dataStore: WKWebsiteDataStore
    private let specialLinkHandler: SpecialLinkHandler

    let model: ServiceView.ViewModel

    init(destinationUrl: URL,
         sourceUrl: URL? = nil,
         dataStore: WKWebsiteDataStore,
         specialLinkHandler: SpecialLinkHandler,
         destinationViewDismissedAction: DismissedAction?) {
        self.sourceUrl = sourceUrl
        self.destinationUrl = destinationUrl
        self.dataStore = dataStore
        self.specialLinkHandler = specialLinkHandler

        model = ServiceView.ViewModel(rootUrl: destinationUrl,
                                      refererUrl: sourceUrl,
                                      websiteDataStore: dataStore,
                                      specialLinkHandler: specialLinkHandler,
                                      backToHomeAction: destinationViewDismissedAction)
    }
}

extension ServiceLinkViewModel: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.url == rhs.url && lhs.dataStore == rhs.dataStore
    }
}

extension ServiceLinkViewModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(dataStore)
    }
}
