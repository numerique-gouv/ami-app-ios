//
//  SpecialLinkHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UIKit

/// The class to handle special links types like `mailto:` or `tel:`.
/// Actually, the only action is to handle a special link to the operating system.
/// if the operating system knows how to process it.
struct SpecialLinkHandler: SpecialLinkProtocol, Sendable {
    /// Returns associated `SpecialLinkType` if any.
    func specialLink(for link: URL) -> SpecialLinkType? {
        SpecialLinkType.linkType(link)
    }

    /// Return `true` if the url is identified as a listed special link type.
    ///
    /// - Parameters:
    ///   - link: the `SpecialLinkType` to handle
    /// - Throws: a `SpecialLinkError` if the operating system can't handle  the listed special link type.
    func handleLink(link: SpecialLinkType) async throws(SpecialLinkError) {
        // If the operating system can't open the link, the error propagates to the caller.
        try await handleSpecialLink(link: link)
    }

    /// Asks the operating system to open the link.
    ///
    /// `UIApplication.shared.open` is isolated to the main actor, which is why `SpecialLinkHandler` is `@MainActor`.
    ///
    /// - Throws: A `SpecialLinkError` if the operating system reports it could not open the link.
    @MainActor
    private func handleSpecialLink(link: SpecialLinkType) async throws(SpecialLinkError) {
        switch link {
        case let .email(emailLink):
            guard await UIApplication.shared.open(emailLink) else {
                throw .systemIsUnableToHandleLink(link)
            }
        case let .phone(phoneLink):
            guard await UIApplication.shared.open(phoneLink) else {
                throw .systemIsUnableToHandleLink(link)
            }
        }
    }
}
