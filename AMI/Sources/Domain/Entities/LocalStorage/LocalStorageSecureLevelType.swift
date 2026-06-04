//
//  LocalStorageSecureLevelType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the security level applied when storing data locally on the device.
/// Each level corresponds to different storage mechanisms and access requirements:
/// - `.low`: Basic storage without encryption (UserDefaults)
/// - `.medium`: Encrypted storage using Keychain
/// - `.high`: Encrypted storage with biometric/passcode protection
enum LocalStorageSecureLevelType {
    /// Data is stored without encryption using UserDefaults.
    /// Suitable for non-sensitive configuration and preference data.
    case low

    /// Data is stored with strong encryption using the system Keychain.
    /// Suitable for sensitive data that doesn't require user authentication.
    case medium

    /// Data is stored using Keychain with biometric (Face ID/Touch ID) or passcode protection.
    /// Requires user authentication on each access. Suitable for highly sensitive data.
    case high
}
