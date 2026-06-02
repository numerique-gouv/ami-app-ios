//
//  LocalStorageSecureLevelType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the security level applied when storing data locally on the device.
enum LocalStorageSecureLevelType {
    /// Data is stored with no encryption (e.g. UserDefaults).
    case low

    /// Data is stored with strong encryption using Keychain.
    case medium

    /// Data is stored using Keychain protected by biometric (Face ID / Touch ID) or passcode authentication.
    case high
}
