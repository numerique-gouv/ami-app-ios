//
//  SpecialLinkType.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A kind of link that the operating system can handle natively.
///
/// Each case's raw value is the URL scheme used to recognize that link kind.
enum SpecialLinkType: Sendable {
    /// An email link (`mailto:`).
    case email(URL)
    /// A phone number link (`tel:`).
    case phone(URL)

    init?(url: URL) {
        guard let scheme = url.scheme else {
            return nil
        }
        switch scheme {
        case "mailto": self = .email(url)
        case "tel": self = .phone(url)
        default: return nil
        }
    }

    var url: URL {
        switch self {
        case let .email(url): url
        case let .phone(url): url
        }
    }

    /// Determines what kind of special link a URL represents, if any.
    ///
    /// - Parameter forUrl: The URL to inspect.
    /// - Returns: The `SpecialLinkType` matching the URL's scheme, or `nil`
    ///            if the URL has no scheme, or its scheme is not a recognized special link.
    static func linkType(_ forUrl: URL) -> SpecialLinkType? {
        SpecialLinkType(url: forUrl)
    }
}
