//
//  LocalStorageRepositoryProtocol.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// sourcery: AutoMockable
/// Defines the interface for reading, writing, and deleting data stored locally on the device.
///
/// Each operation accepts a ``LocalStorageSecureLevelType`` to determine the underlying
/// storage mechanism used (e.g. UserDefaults or Keychain).
/// All operations are asynchronous and return a `Result` type indicating success or a ``LocalStorageErrorType`` failure.
protocol LocalStorageRepositoryProtocol {
    /// Create a LocalStorageRepository dedicated to a user to try to isolate its data from other users' data.
    init(for userStoreID: String)

    // MARK: - Write

    /// Writes a `Bool` value to the local storage for the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be stored.
    ///   - value: The `Bool` value to store.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Writes an `Int` value to the local storage for the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be stored.
    ///   - value: The `Int` value to store.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Writes a `String` value to the local storage for the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be stored.
    ///   - value: The `String` value to store.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    // MARK: - Read

    /// Reads a `Bool` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to retrieve.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing the stored `Bool` on success, or a ``LocalStorageErrorType`` on failure.
    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Reads an `Int` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to retrieve.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing the stored `Int` on success, or a ``LocalStorageErrorType`` on failure.
    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType>

    /// Reads a `String` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to retrieve.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing the stored `String` on success, or a ``LocalStorageErrorType`` on failure.
    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType>

    // MARK: - Delete

    /// Deletes a value from the local storage for the given key.
    /// The operation will be routed to the appropriate storage backend based on the security level.
    /// - Parameters:
    ///   - key: The key of the value to delete.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func delete(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>
}

// sourcery:end
protocol LocalStorageRepositoryJSONProtocol {
    // MARK: - Write

    // Sourcery can't generate a valid ``ReturnValue`` property for generic method. Skip these methods.
    // sourcery: skip
    /// Writes a JSON-serializable value to the local storage for the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be stored.
    ///   - value: The JSON-serializable value to store. It must adopt the Codable protocol to be Encodable now and Decodable later.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func writeJSON(key: String, value: some Codable, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    // MARK: - Read

    // Sourcery can't generate a valid ``ReturnValue`` property for generic method. Skip these methods.
    // sourcery: skip
    /// Reads a JSON-serializable value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to retrieve.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing the stored value on success, or a ``LocalStorageErrorType`` on failure.
    func readJSON<T>(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable
}
