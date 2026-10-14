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
        case .email: AlertModel(title: AMIL10n.Main.commonError,
                                message: AMIL10n.Main.alertCantHandleEmailLink,
                                cancelButtonTitle: AMIL10n.Main.commonOk)
        case .phone: AlertModel(title: AMIL10n.Main.commonError,
                                message: AMIL10n.Main.alertCantHandlePhoneLink,
                                cancelButtonTitle: AMIL10n.Main.commonOk)
        }
    }
}
