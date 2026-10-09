//
//  AliasedUrl.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 06/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct AliasedUrl: Sendable {
    /// The suffix used to identify an URL alias
    /// Supplied by the web page at runtime; not known at compile time.
    /// Matching: a navigation URL matches when its absolute string
    /// ends with this pattern
    let pattern: String
    /// The alias identifying this destination in the app's local catalog.
    /// Always a locally known alias — the repository drops web catalog
    /// entries whose alias isn't in `PromotedAliases`, so this field can
    /// never hold an unknown value.
    let alias: PromotedAliases
    /// How the app must navigate to the destination (native view or continue in webView).
    /// Derived by the repository from `alias.route`
    let destination: Destination

    enum Destination: Equatable, Hashable, Sendable {
        /// Known alias, not eligible for promotion: stay in the web page.
        case webPage
        /// Eligible alias: open the native screen.
        case native(AppRoute)
    }
}

extension AliasedUrl: Equatable {
    /// AliasedUrl values are compared only on their alias property.
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.alias == rhs.alias
    }
}
