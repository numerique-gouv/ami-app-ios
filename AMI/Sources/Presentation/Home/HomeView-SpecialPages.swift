//
//  HomeView-SpecialPages.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

extension HomeView.ViewModel {
    enum SpecialWebPageUrl {
        case notificationsSettings
        case contact

        var suffixes: [String] {
            switch self {
            case .notificationsSettings: ["/#/settings", "/#/preferences/notifications"]
            case .contact: ["/#/contact"]
            }
        }

        // Returns true if url is not null and ends with any of the suffixes of the enum type.
        func match(_ url: URL?) -> Bool {
            guard let url else {
                return false
            }
            return suffixes.contains { url.absoluteString.hasSuffix($0) }
        }
    }
}
