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
    private let storage: UserDefaultsStorage

    /// Storage backend for sensitive data, backed by the system Keychain.
    private let secureStorage: KeychainStorage

    /// Creates a new `LocalStorageRepository`.
    init(for userStoreID: String) {
        storage = UserDefaultsStorage(for: userStoreID)
        secureStorage = KeychainStorage(for: userStoreID)
    }
}

extension LocalStorageRepository: LocalStorageRepositoryProtocol {
    /// Routes a raw `Data` write operation to the appropriate storage backend based on the security level.
    /// This is the core routing method that determines whether data goes to UserDefaults or Keychain.
    ///
    /// ## Routing Logic
    /// - `.low` → UserDefaults (unencrypted, fast access)
    /// - `.medium` → Keychain (encrypted, secure)
    /// - `.high` → Keychain with biometric protection (encrypted, highly secure)
    ///
    /// - Parameters:
    ///   - key: The unique identifier under which the data will be stored.
    ///   - value: The binary data to persist to the chosen backend.
    ///   - secureLevel: Determines the storage mechanism and security level.
    /// - Returns: `.success(true)` on successful storage. Never fails at this abstraction layer.
    private func writeData(key: String, data: Data, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .low: await storage.writeData(data, forKey: key)
        case .medium: await secureStorage.writeData(data, forKey: key, requireAuthentication: false)
        case .high: await secureStorage.writeData(data, forKey: key, requireAuthentication: true)
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
    /// - `.low` → Reads from UserDefaults (unencrypted)
    /// - `.medium` → Reads from Keychain (encrypted)
    /// - `.high` → Reads from Keychain with biometric protection (not yet implemented)
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
        case .low:
            switch await storage.readData(forKey: key) {
            case let .success(data): decodeData(type, data: data)
            case let .failure(error): .failure(error)
            }
        case .medium:
            switch await secureStorage.readData(forKey: key, requireAuthentication: false) {
            case let .success(data): decodeData(type, data: data)
            case let .failure(error): .failure(error)
            }
        case .high:
            switch await secureStorage.readData(forKey: key, requireAuthentication: true) {
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
    /// - `.low` → Deletes from UserDefaults (unencrypted storage)
    /// - `.medium` → Deletes from Keychain without authentication requirement
    /// - `.high` → Deletes from Keychain with biometric/passcode authentication
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
        case .low:
            switch await storage.deleteData(forKey: key) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        case .medium:
            switch await secureStorage.deleteData(forKey: key, requireAuthentication: false) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        case .high:
            switch await secureStorage.deleteData(forKey: key, requireAuthentication: true) {
            case let .success(success): .success(success)
            case let .failure(error): .failure(error)
            }
        }
    }

    /// Permanently removes all data from the specified security level storage backend.
    /// This is a destructive operation that clears all key-value pairs from the chosen storage domain.
    ///
    /// ## Routing Logic
    /// - `.low` → Clears all UserDefaults data in the app's suite
    /// - `.medium` → Attempts to clear all Keychain data (implementation-dependent)
    /// - `.high` → Attempts to clear all Keychain data (implementation-dependent)
    ///
    /// ## Security Implications
    ///
    /// ### Low Security (.low)
    /// - **Scope**: Removes all data from the app's UserDefaults suite
    /// - **Isolation**: Only affects the specific `userStoreID` domain, not system-wide UserDefaults
    /// - **Performance**: Fast operation, immediate effect
    /// - **Reversibility**: **Irreversible** - all application preferences and cached data will be lost
    ///
    /// ### Medium/High Security (.medium/.high)
    /// - **Scope**: Attempts to remove all Keychain items for the app's service
    /// - **Authentication**: May require device passcode or biometric authentication
    /// - **System Integration**: Respects device lock state and security policies
    /// - **Current Limitation**: Keychain implementation currently returns success without actual deletion
    ///
    /// ## Use Cases
    ///
    /// ### Application Reset
    /// ```swift
    /// // Clear all non-sensitive data during app reset
    /// await repository.deleteAll(secureLevel: .low)
    /// ```
    ///
    /// ### User Logout
    /// ```swift
    /// // Clear all sensitive authentication data
    /// await repository.deleteAll(secureLevel: .medium)
    /// await repository.deleteAll(secureLevel: .high)
    /// ```
    ///
    /// ### Privacy Compliance
    /// ```swift
    /// // Complete data erasure for GDPR compliance
    /// await repository.deleteAll(secureLevel: .low)
    /// await repository.deleteAll(secureLevel: .medium)
    /// await repository.deleteAll(secureLevel: .high)
    /// ```
    ///
    /// ## Error Scenarios
    ///
    /// ### Low Security
    /// - Rarely fails; UserDefaults operations are generally reliable
    /// - May fail if file system is read-only or disk is full
    ///
    /// ### Medium/High Security
    /// - **Device Locked**: Operation may fail if device security prevents Keychain access
    /// - **Authentication Required**: User may need to authenticate with passcode/biometric
    /// - **System Restrictions**: Corporate policies or parental controls may block access
    /// - **Hardware Issues**: Secure Enclave problems may cause failures
    ///
    /// ## Implementation Status
    /// - **UserDefaults (.low)**: ✅ Fully implemented, removes all data in suite
    /// - **Keychain (.medium/.high)**: ⚠️ Currently returns success without actual deletion
    ///
    /// ## Thread Safety
    /// This method uses async/await and is safe for concurrent access. However, calling
    /// `deleteAll` while other storage operations are in progress may lead to race conditions
    /// where some data is written after deletion begins.
    ///
    /// ## Performance Considerations
    /// - **Low Security**: Very fast (milliseconds)
    /// - **Medium/High Security**: May be slower due to Keychain access and potential authentication prompts
    /// - **Network**: No network access required; all operations are local
    ///
    /// - Parameter secureLevel: Determines which storage backend to clear.
    ///   Choose the same level used when storing the data you want to remove.
    /// - Returns: `.success(true)` if the deletion operation completes successfully,
    ///   or `.failure(LocalStorageErrorType)` if system-level errors prevent the operation.
    ///
    /// - Warning: This operation is **irreversible**. Ensure you have appropriate user confirmation
    ///   and backup mechanisms in place before calling this method.
    ///
    /// - Important: For medium and high security levels, the current Keychain implementation
    ///   does not actually delete data but always returns success. This will be addressed in future updates.
    func deleteAll(secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .low: await storage.deleteAll()
        case .medium: await secureStorage.deleteAll(requireAuthentication: false)
        case .high: await secureStorage.deleteAll(requireAuthentication: true)
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
