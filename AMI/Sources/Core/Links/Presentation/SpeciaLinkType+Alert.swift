//
//  SpeciaLinkType+Alert.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// Presentation layer (e.g. Features/…/Presentation/ or Core/UI)
extension SpecialLinkType {
    var unableToHandleAlert: AlertModel {
        switch self {
        case .email: AlertModel(title: AMIL10n.commonError,
                                message: AMIL10n.alertCantHandleEmailLink,
                                closeButtonTitle: AMIL10n.commonOk)
        case .phone: AlertModel(title: AMIL10n.commonError,
                                message: AMIL10n.alertCantHandlePhoneLink,
                                closeButtonTitle: AMIL10n.commonOk)
        }
    }
}
