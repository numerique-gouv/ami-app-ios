//
//  DestinationLink.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 01/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct DestinationLink: Hashable {
    typealias DismissedAction = () -> Void

    private let url: URL
    private let dataStore: WKWebsiteDataStore

    let model: PartnerView.ViewModel

    init(url: URL, dataStore: WKWebsiteDataStore, destinationViewDismissedAction: DismissedAction?) {
        self.url = url
        self.dataStore = dataStore

        model = PartnerView.ViewModel(websiteDataStore: dataStore,
                                      rootUrl: url,
                                      backToHomeAction: destinationViewDismissedAction)
    }
}
