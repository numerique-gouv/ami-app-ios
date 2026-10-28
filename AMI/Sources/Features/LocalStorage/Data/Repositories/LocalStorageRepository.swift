//
//  LocalStorageRepository.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A repository that unifies access to both unprotected and protected local storage.
/// Routes read/write/delete operations to the appropriate storage backend
/// (`UserDefaults` or Keychain) based on the requested security level.
struct LocalStorageRepository {
    /// Storage backend for non-sensitive data, backed by `UserDefaults`.
    private let privateStorage: UserDefaultsStorage

    /// Storage backend for sensitive data, backed by the system Keychain.
    private let securedStorage: KeychainStorage

    /// Creates a new `LocalStorageRepository`.
    init(for userStoreID: String) {
        privateStorage = UserDefaultsStorage(for: userStoreID)
        securedStorage = KeychainStorage(for: userStoreID)
    }
}

extension LocalStorageRepository: LocalStorageRepositoryProtocol {
    /// Routes a raw `Data` write operation to the appropriate storage backend based on the security level.
    /// This is the core routing method that determines whether data goes to UserDefaults or Keychain.
    ///
    /// ## Routing Logic
    /// - `.private` → UserDefaults (unencrypted, fast access)
    /// - `.encrypted` → Keychain (encrypted, secure)
    /// - `.authenticated` → Keychain with biometric protection (encrypted, highly secure)
    ///
    /// - Parameters:
    ///   - key: The unique identifier under which the data will be stored.
    ///   - value: The binary data to persist to the chosen backend.
    ///   - secureLevel: Determines the storage mechanism and security level.
    /// - Returns: `.success(true)` on successful storage. Never fails at this abstraction layer.
    private func writeData(key: String, data: Data, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .private: await privateStorage.writeData(data, forKey: key)
        case .encrypted: await securedStorage.writeData(data, forKey: key, requireAuthentication: false)
        case .authenticated: await securedStorage.writeData(data, forKey: key, requireAuthentication: true)
        }
    }

    /// Encodes a `Bool` value to `Data` and persists it under the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be saved.
    ///   - value: The boolean value to store.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on success, or `.failure(.typeMismatch)` if encoding fails.
    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case .failure: .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
        case let .success(data): await writeData(key: key, data: data, secureLevel: secureLevel)
        }
    }

    /// Encodes an `Int` value to `Data` and persists it under the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be saved.
    ///   - value: The integer value to store.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on success, or `.failure(.typeMismatch)` if encoding fails.
    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case .failure: .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
        case let .success(data): await writeData(key: key, data: data, secureLevel: secureLevel)
        }
    }

    /// Encodes a `String` value to `Data` and persists it under the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be saved.
    ///   - value: The string value to store.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on success, or `.failure(.typeMismatch)` if encoding fails.
    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case .failure: .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
        case let .success(data): await writeData(key: key, data: data, secureLevel: secureLevel)
        }
    }

    /// Encodes a `Codable` value as JSON and stores it securely.
    /// This method provides type-safe storage for complex data structures by serializing
    /// them to JSON before routing to the appropriate storage backend.
    ///
    /// ## Type Safety
    /// The value must conform to `Codable` (both `Encodable` and `Decodable`) to ensure
    /// it can be both stored and retrieved successfully. A runtime check verifies this.
    ///
    /// - Parameters:
    ///   - key: The unique identifier under which the JSON data will be stored.
    ///   - value: The `Codable` value to serialize and store. Must be both encodable and decodable.
    ///   - secureLevel: Determines the storage mechanism (UserDefaults vs Keychain).
    /// - Returns: `.success(true)` on successful encoding and storage, or `.failure(.typeMismatch)`
    ///   if the value cannot be encoded to JSON or lacks proper `Codable` conformance.
    ///
    /// - Important: The runtime `Codable` check should be replaced with compile-time safety in future versions.
    func writeJSON(key: String, value: some Codable, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case .failure: .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
        case let .success(data): await writeData(key: key, data: data, secureLevel: secureLevel)
        }
    }

    /// Reads and decodes stored data from the appropriate backend into the specified type.
    /// This is the core retrieval method that handles routing, data fetching, and JSON decoding.
    ///
    /// ## Backend Routing
    /// - `.private` → Reads from UserDefaults (unencrypted)
    /// - `.encrypted` → Reads from Keychain (encrypted)
    /// - `.authenticated` → Reads from Keychain with biometric protection (not yet implemented)
    ///
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the stored JSON data into.
    ///   - key: The unique identifier for the stored data.
    ///   - secureLevel: Determines which storage backend to query.
    /// - Returns: `.success(T)` with the decoded value if found and valid,
    ///   `.failure(.keyNotFound)` if no data exists, or `.failure(.typeMismatch)` if decoding fails.
    ///
    /// - Important: High security level should implement biometric authentication but currently
    ///   falls back to standard Keychain access.
    private func readDataAsType<T>(_ type: T.Type = T.self, key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        switch secureLevel {
        case .private:
            switch await privateStorage.readData(forKey: key) {
            case let .success(data): decodeData(type, data: data)
            case let .failure(error): .failure(error)
            }
        case .encrypted:
            switch await securedStorage.readData(forKey: key, requireAuthentication: false) {
            case let .success(data): decodeData(type, data: data)
            case let .failure(error): .failure(error)
            }
        case .authenticated:
            switch await securedStorage.readData(forKey: key, requireAuthentication: true) {
            case let .success(data): decodeData(type, data: data)
            case let .failure(error): .failure(error)
            }
        }
    }

    /// Attempts to decode raw binary data into the specified `Decodable` type using JSON deserialization.
    /// This is a utility method that handles the JSON decoding process with proper error wrapping.
    ///
    /// - Parameters:
    ///   - type: The target `Decodable` type for deserialization.
    ///   - data: The raw binary data containing JSON to decode.
    /// - Returns: `.success(T)` with the decoded object if deserialization succeeds,
    ///   or `.failure(.typeMismatch)` with the underlying JSON decoding error.
    ///
    /// - Note: Uses `JSONDecoder` with default settings. Future versions might support
    ///   custom decoding strategies or date formatters.
    private func decodeData<T>(_ type: T.Type = T.self, data: Data) -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        do {
            return try .success(JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
        }
    }

    /// Reads and decodes a `Bool` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(Bool)` or a relevant `.failure`.
    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        await readDataAsType(Bool.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes an `Int` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(Int)` or a relevant `.failure`.
    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType> {
        await readDataAsType(Int.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes a `String` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(String)` or a relevant `.failure`.
    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType> {
        await readDataAsType(String.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes a JSON-encoded value of type `T` stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(T)` if found and decodable, or a relevant `.failure`.
    func readJSON<T>(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        await readDataAsType(T.self, key: key, secureLevel: secureLevel)
    }

    /// Deletes the value associated with the given key from the appropriate storage backend.
    /// This method routes deletion operations to the correct storage system based on the security level
    /// used when the data was originally stored.
    ///
    /// ## Backend Routing
    /// - `.private` → Deletes from UserDefaults (unencrypted storage)
    /// - `.encrypted` → Deletes from Keychain without authentication requirement
    /// - `.authenticated` → Deletes from Keychain with biometric/passcode authentication
    ///
    /// ## Behavior
    /// - **Idempotent**: Safe to call multiple times with the same key
    /// - **No Verification**: Does not check if the key exists before attempting deletion
    /// - **Silent Success**: Returns success even if the key was not present
    /// - **Authentication**: High security level may prompt for device authentication
    ///
    /// ## Error Scenarios
    /// - **Low Security**: Rarely fails; UserDefaults deletions are generally reliable
    /// - **Medium/High Security**: May fail if Keychain access is restricted or device is locked
    /// - **Authentication Failure**: High security deletion fails if user cancels authentication
    ///
    /// ## Usage Examples
    /// ```swift
    /// // Delete non-sensitive cached data
    /// await repository.delete(key: "userPreferences", secureLevel: .low)
    ///
    /// // Delete sensitive authentication token
    /// await repository.delete(key: "authToken", secureLevel: .medium)
    ///
    /// // Delete highly sensitive biometric-protected data
    /// await repository.delete(key: "encryptionKey", secureLevel: .high)
    /// ```
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the value to remove. Must match the key used during storage.
    ///   - secureLevel: Determines which storage backend is queried. Should match the security level
    ///     used when storing the data to ensure deletion targets the correct backend.
    /// - Returns: `.success(true)` if the deletion operation completes successfully,
    ///   or `.failure(LocalStorageErrorType)` if system-level errors prevent the operation.
    ///
    /// - Important: Always use the same security level for deletion that was used for storage.
    ///   Using a different security level will attempt to delete from the wrong backend,
    ///   leaving the actual data intact in the original storage location.
    func delete(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .private:
            switch await privateStorage.deleteData(forKey: key) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        case .encrypted:
            switch await securedStorage.deleteData(forKey: key, requireAuthentication: false) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        case .authenticated:
            switch await securedStorage.deleteData(forKey: key, requireAuthentication: true) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        }
    }

    /// Permanently removes all data from the specified security level storage backend.
    ///
    /// ## Routing Logic
    /// - `.private` → Clears all UserDefaults data in the app's suite
    /// - `.encrypted` → Clears all Keychain data for this service without authentication
    /// - `.authenticated` → Clears all Keychain data for this service with biometric/passcode authentication
    ///
    /// ## Important Notes
    /// - **Irreversible**: All data is permanently lost
    /// - **Authentication**: High security level requires device authentication; medium does not
    /// - **Complete Deletion**: Each security level clears its own storage backend independently
    /// - **Service Isolation**: Only affects this app's storage, not system-wide data
    ///
    /// ## Error Scenarios
    /// - **Low Security**: Rarely fails; UserDefaults clearing is generally reliable
    /// - **Medium Security**: May fail if Keychain access is restricted or system error occurs
    /// - **High Security**: May fail if device is locked, Keychain access is restricted, or authentication requirements cannot be met
    ///
    /// - Parameter secureLevel: Determines which storage backend to clear and authentication requirements
    /// - Returns: `.success(true)` if successful, or `.failure(LocalStorageErrorType)` if system error occurs
    ///
    /// - Warning: This operation is **irreversible**. Ensure proper confirmation before use.
    func deleteAll(secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .private: await privateStorage.deleteAll()
        case .encrypted: await securedStorage.deleteAll(requireAuthentication: false)
        case .authenticated: await securedStorage.deleteAll(requireAuthentication: true)
        }
    }
}

extension Encodable {
    /// Convenience property for encoding any `Encodable` value to JSON `Data`.
    /// This extension provides a unified encoding interface used throughout the storage layer
    /// to serialize values before persistence.
    ///
    /// ## Usage
    /// ```swift
    /// let user = User(name: "John", age: 30)
    /// switch user.toData {
    /// case .success(let data):
    ///     // Store the JSON data
    /// case .failure(let error):
    ///     // Handle encoding error
    /// }
    /// ```
    ///
    /// - Returns: `.success(Data)` containing the JSON representation if encoding succeeds,
    ///   or `.failure(Error)` with the underlying encoding error if it fails.
    ///
    /// - Note: Uses `JSONEncoder` with default settings. Custom encoding strategies
    ///   may be needed for complex types with special formatting requirements.
    var toData: Result<Data, Error> {
        do {
            return try .success(JSONEncoder().encode(self))
        } catch {
            return .failure(error)
        }
    }
}
