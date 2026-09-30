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

    private let url: URL
    private let dataStore: WKWebsiteDataStore
    private let specialLinkHandler: SpecialLinkHandler

    let model: ServiceView.ViewModel

    init(url: URL,
         dataStore: WKWebsiteDataStore,
         specialLinkHandler: SpecialLinkHandler,
         destinationViewDismissedAction: DismissedAction?) {
        self.url = url
        self.dataStore = dataStore
        self.specialLinkHandler = specialLinkHandler

        model = ServiceView.ViewModel(rootUrl: url,
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
