//
//  SpecialLinkError+Alert.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// Presentation layer (e.g. Features/…/Presentation/ or Core/UI)
extension SpecialLinkError {
    /// The alert models in case the system is unable to handle special link.
    var alert: AlertModel {
        switch self {
        case let .systemIsUnableToHandleLink(type, _): type.unableToHandleAlert
        }
    }
}
