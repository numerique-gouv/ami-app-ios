//
//  DeviceID.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 02/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The application's device identifier.
///
/// A unique value identifying this application installation on the current
/// device. The backend correlates it with the user account to maintain
/// per-device state — notably the push-notification consent.
///
/// The identifier is a plain `String` (a UUID, as produced by the
/// `DeviceIDProvider` implementation). The alias gives the Domain layer a
/// named type so that port signatures and use cases don't leak a bare
/// `String`, and so the representation stays swappable.
typealias DeviceID = String
