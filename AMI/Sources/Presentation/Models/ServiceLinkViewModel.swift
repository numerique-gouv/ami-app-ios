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

    private let sourceUrl: URL?
    private let destinationUrl: URL
    private let dataStore: WKWebsiteDataStore

    let model: ServiceView.ViewModel

    init(destinationUrl: URL, sourceUrl: URL? = nil, dataStore: WKWebsiteDataStore, destinationViewDismissedAction: DismissedAction?) {
        self.sourceUrl = sourceUrl
        self.destinationUrl = destinationUrl
        self.dataStore = dataStore

        model = ServiceView.ViewModel(websiteDataStore: dataStore,
                                      rootUrl: destinationUrl,
                                      refererUrl: sourceUrl,
                                      backToHomeAction: destinationViewDismissedAction)
    }
}
