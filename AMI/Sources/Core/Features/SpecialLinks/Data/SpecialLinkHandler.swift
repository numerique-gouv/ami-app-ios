//
//  SpecialLinkHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit

@MainActor
struct SpecialLinkHandler: SpecialLinkProtocol {
    func handleLink(link: URL) async throws(SpecialLinkError) -> Bool {
        // If not a special link → the caller applies default handling.
        guard let linkType = SpecialLinkType.linkType(link) else {
            return false
        }

        // If the system cannot open the link, the error propagates to the caller.
        try await handleSpecialLink(type: linkType, link: link)

        // The system opened the link.
        return true
    }

    /// Asks the system to open the link.
    ///
    /// `UIApplication.shared.open` is isolated to the main actor, which is why `SpecialLinkHandler` is `@MainActor`.
    ///
    /// - Throws: A `SpecialLinkError` if the system reports it could not open the link.
    private func handleSpecialLink(type: SpecialLinkType, link: URL) async throws(SpecialLinkError) {
        guard await UIApplication.shared.open(link) else {
            throw .systemIsUnableToHandleLink(type, link)
        }
    }
}
