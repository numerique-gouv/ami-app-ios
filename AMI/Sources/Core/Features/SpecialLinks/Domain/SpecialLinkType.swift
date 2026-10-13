//
//  SpecialLinkType.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A kind of link that the system can handle natively.
///
/// Each case's raw value is the URL scheme used to recognize that link kind.
enum SpecialLinkType: String {
    /// An email link (`mailto:`).
    case email = "mailto"
    /// A phone number link (`tel:`).
    case phone = "tel"

    /// Determines what kind of special link a URL represents, if any.
    ///
    /// - Parameter forUrl: The URL to inspect.
    /// - Returns: The `SpecialLinkType` matching the URL's scheme, or `nil`
    ///            if the URL has no scheme, or its scheme is not a recognized special link.
    static func linkType(_ forUrl: URL) -> SpecialLinkType? {
        guard let urlScheme = forUrl.scheme else {
            return nil
        }
        return SpecialLinkType(rawValue: urlScheme)
    }
}
