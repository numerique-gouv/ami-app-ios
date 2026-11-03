//
//  SpecialLinkProtocol.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

protocol SpecialLinkProtocol: Sendable {
    /// Returns associated `SpecialLinkType` if any.
    func specialLink(for link: URL) -> SpecialLinkType?

    /// Attempts to handle a special link.
    ///
    /// Suspends until handling has completed, or a `SpecialLinkError` is thrown.
    ///
    /// - Parameter link: The URL of the link to handle.
    ///
    /// - Throws: A `SpecialLinkError` if `link` is one of the special types defined in `SpecialLinkType`
    ///           but the operating system can't handle it (for example, dialing a phone number in the iOS Simulator).
    func handleLink(link: SpecialLinkType) async throws(SpecialLinkError)
}
