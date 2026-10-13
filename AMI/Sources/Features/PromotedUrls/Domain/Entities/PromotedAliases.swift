//
//  PromotedAliases.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 06/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum PromotedAliases: String, CaseIterable, Sendable {
    case welcomeNotificationsActivation = "welcome:notifications:activation"
    case preferencesNotificationsActivation = "preferences:notifications:activation"

    /// Screen the alias opens. `nil` = known but not currently eligible
    /// (navigation stays in the web page).
    var route: AppRoute? {
        switch self {
        case .welcomeNotificationsActivation: nil // Not native for the moment
        case .preferencesNotificationsActivation: .amiNotificationsSettings
        }
    }
}
