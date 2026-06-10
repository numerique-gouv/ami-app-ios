//
//  LocalStorageSecureLevelType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the security levels available when storing data locally on the device.
///
/// Each security level corresponds to different storage mechanisms and access requirements,
/// providing a clear separation between different types of data based on their sensitivity.
/// This enum is used throughout the Data layer to route storage operations to the appropriate
/// backend (UserDefaults vs Keychain) based on security requirements defined by the Domain layer.
///
/// ## Storage Backend Mapping
/// - `.low` → UserDefaults (unencrypted, fast access)
/// - `.medium` → Keychain (encrypted, secure)
/// - `.high` → Keychain with biometric/passcode protection (encrypted, highly secure)
///
/// ## Performance Characteristics
/// - **Low**: Fastest access, immediate availability, no authentication overhead
/// - **Medium**: Moderate performance, encrypted storage, Keychain lookup overhead
/// - **High**: Slowest access due to authentication prompts, maximum security
///
/// ## Use Case Examples
/// ```swift
/// // Non-sensitive preferences
/// await repository.writeString(key: "theme", value: "dark", secureLevel: .low)
///
/// // API tokens and sensitive data
/// await repository.writeString(key: "authToken", value: token, secureLevel: .medium)
///
/// // Highly sensitive user data requiring biometric protection
/// await repository.writeJSON(key: "biometricData", value: userData, secureLevel: .high)
/// ```
enum LocalStorageSecureLevelType {
    /// Data is stored without encryption using UserDefaults.
    ///
    /// **Storage Backend**: UserDefaults
    /// **Encryption**: None
    /// **Authentication**: Not required
    /// **Access Speed**: Fastest
    ///
    /// ## Suitable For:
    /// - Application preferences and settings
    /// - User interface state and configuration
    /// - Non-sensitive cached data
    /// - Feature flags and toggles
    /// - Display preferences (theme, language, etc.)
    ///
    /// ## Security Warning:
    /// Data stored at this level is accessible to anyone with access to the device's
    /// file system, app backups, or debugging tools. Never use for sensitive information.
    case low

    /// Data is stored with strong encryption using the system Keychain.
    ///
    /// **Storage Backend**: System Keychain
    /// **Encryption**: Hardware-accelerated AES encryption
    /// **Authentication**: Device unlock required
    /// **Access Speed**: Moderate
    ///
    /// ## Suitable For:
    /// - API authentication tokens
    /// - Service credentials and passwords
    /// - Encrypted user data
    /// - Session identifiers
    /// - Private keys and certificates
    ///
    /// ## Security Features:
    /// - Data is encrypted using the device's hardware security module
    /// - Automatically protected by device lock screen
    /// - Isolated from other applications
    /// - Not included in standard device backups
    case medium

    /// Data is stored using Keychain with biometric (Face ID/Touch ID) or passcode protection.
    ///
    /// **Storage Backend**: System Keychain with authentication policy
    /// **Encryption**: Hardware-accelerated AES encryption
    /// **Authentication**: Biometric or passcode required for each access
    /// **Access Speed**: Slowest due to authentication prompts
    ///
    /// ## Suitable For:
    /// - Highly sensitive personal information
    /// - Financial data and payment information
    /// - Medical or health records
    /// - Legal documents or identification data
    /// - Any data requiring explicit user consent for access
    ///
    /// ## Security Features:
    /// - Requires user authentication for every read/write operation
    /// - Protected by device's biometric or passcode security
    /// - Maximum protection against unauthorized access
    /// - Audit trail for access attempts
    ///
    /// ## User Experience:
    /// Users will see authentication prompts (Face ID, Touch ID, or passcode entry)
    /// each time the app needs to access this data. Plan UX accordingly to minimize
    /// authentication frequency while maintaining security.
    case high
}
