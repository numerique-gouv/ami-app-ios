//
//  SpecialLinkError.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// An error indicating that the operating system was unable to handle a special link.
enum SpecialLinkError: Error {
    /// The system is unable to handle the given link.
    ///
    /// Carries the link type that could not be handled (for example, a `tel:` link
    /// on a target without telephony, such as the iOS Simulator).
    /// The real web link is carried by the `SpeciallinkType` as its associated value.
    case systemIsUnableToHandleLink(_ type: SpecialLinkType)
}

extension SpecialLinkError: LocalizedError {
    /// A human-readable description, such as `System is unable to handle link "tel:0123456789"`.
    var errorDescription: String? {
        switch self {
        case let .systemIsUnableToHandleLink(type): AMIL10n.errorSystemIsUnableToHandleLink(type.url.absoluteString)
        }
    }
}
