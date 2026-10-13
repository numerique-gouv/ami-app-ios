//
//  SpecialLinkProtocol.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

protocol SpecialLinkProtocol {
    /// Attempts to handle a special link.
    ///
    /// Suspends until handling has completed, or a `SpecialLinkError` is thrown.
    ///
    /// - Parameter link: The URL of the link to handle.
    /// - Returns: `true` if `link` is one of the special types defined in `SpecialLinkType`,
    ///            `false` if it is not a special link, in which case the caller should apply default handling.
    /// - Throws: A `SpecialLinkError` if `link` is one of the special types defined in `SpecialLinkType`
    ///           but the system cannot handle it (for example, dialing a phone number in the iOS Simulator).
    func handleLink(link: URL) async throws(SpecialLinkError) -> Bool
}
