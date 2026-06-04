//
//  SecureStorageProtocol.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the interface for secure storage operations with optional authentication requirements.
/// Implementations typically use the system Keychain for secure data persistence with optional
/// biometric or passcode protection when authentication is required.
protocol SecureStorageProtocol {
    /// Securely stores binary data for the given key with optional authentication requirement.
    /// - Parameters:
    ///   - data: The binary data to store securely.
    ///   - key: The unique identifier for the stored data.
    ///   - requireAuthentication: Whether accessing this data should require biometric/passcode authentication.
    func writeData(_ data: Data, forKey key: String, requireAuthentication: Bool)

    /// Retrieves securely stored binary data for the given key with authentication if required.
    /// - Parameters:
    ///   - key: The unique identifier for the stored data.
    ///   - requireAuthentication: Whether this data requires biometric/passcode authentication to access.
    /// - Returns: The stored binary data, or `nil` if no data exists for the key or authentication fails.
    func readData(forKey key: String, requireAuthentication: Bool) -> Data?

    /// Removes securely stored data for the given key with authentication if required.
    /// - Parameters:
    ///   - key: The unique identifier for the data to remove.
    ///   - requireAuthentication: Whether removing this data requires biometric/passcode authentication.
    func deleteData(forKey key: String, requireAuthentication: Bool)
}
