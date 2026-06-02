//
//  KeychainStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import KeychainAccess

/// A secure storage abstraction layer over the system Keychain.
/// Provides a simple key-value interface for persisting sensitive binary data,
/// scoped to the app's bundle identifier as the Keychain service.
struct KeychainStorage {

    /// The key type used to identify stored values.
    typealias KeyType = String

    /// The underlying `Keychain` instance used for secure persistence.
    private let store: Keychain

    /// Creates a new `KeychainStorage` instance scoped to the app's bundle identifier.
    /// The Keychain service is automatically set to `AppBundle.identifier()`.
    init() {
        store = Keychain(service: AppBundle.identifier())
    }

    /// Securely persists a `Data` value associated with the given key.
    /// Overwrites any existing value stored under the same key.
    /// - Parameters:
    ///   - value: The binary data to store securely in the Keychain.
    ///   - key: The key under which the data will be saved.
    ///   - secureLevel: The security level to apply when storing the data.
    func writeData(_ value: Data, forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) {
        store[data: key] = value
    }

    /// Retrieves the `Data` value associated with the given key from the Keychain.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: The security level associated with the stored data.
    /// - Returns: The stored `Data`, or `nil` if no value exists for the key.
    func readData(forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) -> Data? {
        store[data: key]
    }

    /// Removes the value associated with the given key from the Keychain.
    /// Setting the value to `nil` effectively deletes the entry.
    /// Has no effect if no value exists for the key.
    /// - Parameters:
    ///   - key: The key identifying the value to remove.
    ///   - secureLevel: The security level associated with the stored data.
    func deleteData(forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) {
        store[data: key] = nil
    }
}

/// Adds debug support for `KeychainStorage`.
extension KeychainStorage: CustomDebugStringConvertible {

    /// A human-readable representation of the Keychain store contents.
    /// Delegates to the underlying `Keychain` instance's debug description.
    /// Useful for debugging — ensure this is never exposed in production logs.
    var debugDescription: String {
        store.debugDescription
    }
}
