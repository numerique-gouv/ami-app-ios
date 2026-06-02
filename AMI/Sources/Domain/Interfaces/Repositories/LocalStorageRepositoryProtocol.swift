//
//  LocalStorageRepositoryProtocol.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the interface for reading, writing, and deleting data stored locally on the device.
///
/// Each operation accepts a ``LocalStorageSecureLevelType`` to determine the underlying
/// storage mechanism used (e.g. UserDefaults or Keychain).
/// All operations are asynchronous and return a `Result` type indicating success or a ``LocalStorageErrorType`` failure.
protocol LocalStorageRepositoryProtocol {
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

    /// Writes a JSON-serializable value to the local storage for the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be stored.
    ///   - value: The JSON-serializable value to store.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func writeJSON(key: String, value: Any, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

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

    /// Reads a JSON-serializable value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to retrieve.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing the stored value on success, or a ``LocalStorageErrorType`` on failure.
    func readJSON(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Any, LocalStorageErrorType>

    // MARK: - Delete

    /// Deletes a `Bool` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to delete.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func deleteBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Deletes an `Int` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to delete.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func deleteInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Deletes a `String` value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to delete.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func deleteString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Deletes a JSON-serializable value from the local storage for the given key.
    /// - Parameters:
    ///   - key: The key of the value to delete.
    ///   - secureLevel: The security level determining the storage mechanism to use.
    /// - Returns: A `Result` containing `true` on success, or a ``LocalStorageErrorType`` on failure.
    func deleteJSON(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>
}
