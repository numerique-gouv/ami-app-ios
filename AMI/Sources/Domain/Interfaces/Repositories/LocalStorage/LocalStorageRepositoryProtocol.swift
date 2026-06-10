//
//  LocalStorageRepositoryProtocol.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// sourcery: AutoMockable
/// Defines the interface for the LocalStorage system's Data layer repository.
///
/// This protocol provides a unified interface for reading, writing, and deleting data
/// stored locally on the device. It abstracts the underlying storage mechanisms
/// (UserDefaults and Keychain) behind a single, type-safe interface that routes operations
/// based on the specified security level.
///
/// ## Architecture Role
/// This protocol serves as the boundary between the Domain and Data layers in the
/// LocalStorage system. It provides:
/// - Type-safe storage operations for basic Swift types
/// - JSON serialization support for complex objects
/// - Security-level-based routing to appropriate storage backends
/// - Consistent error handling across all storage operations
/// - User isolation through store identifiers
///
/// ## Security Model
/// Each operation accepts a `LocalStorageSecureLevelType` parameter that determines
/// which storage backend is used:
/// - `.low` → UserDefaults (unencrypted, fast access)
/// - `.medium` → Keychain (encrypted, secure access)
/// - `.high` → Keychain with biometric authentication (maximum security)
///
/// ## Error Handling
/// All operations are asynchronous and return `Result<T, LocalStorageErrorType>`
/// to provide explicit error handling. The Domain layer can respond appropriately
/// to different failure scenarios including authentication failures, missing keys,
/// and system-level errors.
///
/// ## User Isolation
/// The repository supports user-specific storage isolation through the `userStoreID`
/// parameter in the initializer. This allows multiple users or contexts to maintain
/// separate data stores without interference.
protocol LocalStorageRepositoryProtocol {
    /// Creates a LocalStorageRepository instance dedicated to a specific user or context.
    ///
    /// The user store identifier enables data isolation between different users, app contexts,
    /// or feature areas. Each identifier creates a separate storage namespace to prevent
    /// data interference and enable clean user switching.
    ///
    /// ## Implementation Details
    /// - UserDefaults: Creates a suite named `{bundleID}.{userStoreID}`
    /// - Keychain: Creates a service named `{bundleID}.{userStoreID}`
    ///
    /// ## Usage Examples
    /// ```swift
    /// let userRepo = LocalStorageRepository(for: "user_123")
    /// let cacheRepo = LocalStorageRepository(for: "cache")
    /// let testRepo = LocalStorageRepository(for: "integration_tests")
    /// ```
    ///
    /// - Parameter userStoreID: A unique identifier for this storage instance.
    ///   Should be descriptive and consistent across app launches.
    init(for userStoreID: String)

    // MARK: - Write Operations

    /// Stores a `Bool` value in local storage with the specified security level.
    ///
    /// The value will be JSON-encoded before storage to ensure consistent serialization
    /// across all storage backends. Any existing value for the same key will be overwritten.
    ///
    /// ## Security Routing
    /// - `.low` → UserDefaults (immediate, unencrypted storage)
    /// - `.medium` → Keychain (encrypted storage)
    /// - `.high` → Keychain with authentication prompt
    ///
    /// - Parameters:
    ///   - key: A unique string identifier for this value. Must not be empty.
    ///   - value: The boolean value to store.
    ///   - secureLevel: Determines the storage backend and security measures applied.
    /// - Returns: `.success(true)` on successful storage, or `.failure(LocalStorageErrorType)` for any errors.
    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Stores an `Int` value in local storage with the specified security level.
    ///
    /// The value will be JSON-encoded before storage to ensure consistent serialization
    /// across all storage backends. Any existing value for the same key will be overwritten.
    ///
    /// ## Security Routing
    /// - `.low` → UserDefaults (immediate, unencrypted storage)
    /// - `.medium` → Keychain (encrypted storage)
    /// - `.high` → Keychain with authentication prompt
    ///
    /// - Parameters:
    ///   - key: A unique string identifier for this value. Must not be empty.
    ///   - value: The integer value to store.
    ///   - secureLevel: Determines the storage backend and security measures applied.
    /// - Returns: `.success(true)` on successful storage, or `.failure(LocalStorageErrorType)` for any errors.
    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Stores a `String` value in local storage with the specified security level.
    ///
    /// The value will be JSON-encoded before storage to ensure consistent serialization
    /// across all storage backends. Any existing value for the same key will be overwritten.
    ///
    /// ## Security Routing
    /// - `.low` → UserDefaults (immediate, unencrypted storage)
    /// - `.medium` → Keychain (encrypted storage)
    /// - `.high` → Keychain with authentication prompt
    ///
    /// - Parameters:
    ///   - key: A unique string identifier for this value. Must not be empty.
    ///   - value: The string value to store.
    ///   - secureLevel: Determines the storage backend and security measures applied.
    /// - Returns: `.success(true)` on successful storage, or `.failure(LocalStorageErrorType)` for any errors.
    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    // MARK: - Read Operations

    /// Retrieves a stored `Bool` value from local storage.
    ///
    /// The stored JSON data will be decoded back to a Bool value. If the key doesn't exist
    /// or the stored data can't be decoded as a Bool, appropriate errors are returned.
    ///
    /// ## Security Routing
    /// The security level determines which storage backend is queried and what
    /// authentication (if any) is required to access the data.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the stored value.
    ///   - secureLevel: Determines the storage backend to query and authentication required.
    /// - Returns: `.success(Bool)` with the stored value, or `.failure(LocalStorageErrorType)`
    ///   for errors like missing keys, type mismatches, or authentication failures.
    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Retrieves a stored `Int` value from local storage.
    ///
    /// The stored JSON data will be decoded back to an Int value. If the key doesn't exist
    /// or the stored data can't be decoded as an Int, appropriate errors are returned.
    ///
    /// ## Security Routing
    /// The security level determines which storage backend is queried and what
    /// authentication (if any) is required to access the data.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the stored value.
    ///   - secureLevel: Determines the storage backend to query and authentication required.
    /// - Returns: `.success(Int)` with the stored value, or `.failure(LocalStorageErrorType)`
    ///   for errors like missing keys, type mismatches, or authentication failures.
    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType>

    /// Retrieves a stored `String` value from local storage.
    ///
    /// The stored JSON data will be decoded back to a String value. If the key doesn't exist
    /// or the stored data can't be decoded as a String, appropriate errors are returned.
    ///
    /// ## Security Routing
    /// The security level determines which storage backend is queried and what
    /// authentication (if any) is required to access the data.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the stored value.
    ///   - secureLevel: Determines the storage backend to query and authentication required.
    /// - Returns: `.success(String)` with the stored value, or `.failure(LocalStorageErrorType)`
    ///   for errors like missing keys, type mismatches, or authentication failures.
    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType>

    // MARK: - Delete Operations

    /// Permanently removes a stored value from local storage.
    ///
    /// This operation deletes the data associated with the specified key from the appropriate
    /// storage backend. The operation is routed based on the security level to ensure deletion
    /// occurs in the same backend where the data was originally stored.
    ///
    /// ## Behavior
    /// - No error occurs if the key doesn't exist (idempotent operation)
    /// - The operation is permanent and cannot be undone
    /// - High security operations may require authentication for deletion
    ///
    /// ## Security Routing
    /// - `.low` → Removes from UserDefaults
    /// - `.medium` → Removes from Keychain without authentication
    /// - `.high` → Removes from Keychain (may require authentication)
    ///
    /// - Parameters:
    ///   - key: The unique string identifier of the value to remove.
    ///   - secureLevel: Determines the storage backend to target for deletion.
    /// - Returns: `.success(true)` when deletion completes successfully, or
    ///   `.failure(LocalStorageErrorType)` for authentication or system errors.
    func delete(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    /// Permanently removes all stored data for the specified security level.
    ///
    /// This operation clears all data from the storage backend corresponding to the
    /// specified security level. This is a destructive operation that cannot be undone.
    ///
    /// ## Behavior
    /// - `.low` → Clears entire UserDefaults suite for this user store
    /// - `.medium` → Clears all Keychain items for this service (without authentication)
    /// - `.high` → Clears all Keychain items for this service (may require authentication)
    ///
    /// ## Use Cases
    /// - User logout and data cleanup
    /// - App reset or troubleshooting
    /// - Privacy compliance (data deletion requests)
    /// - Development and testing cleanup
    ///
    /// - Warning: This operation permanently deletes all stored data at the specified
    ///   security level and cannot be undone. Use with extreme caution.
    ///
    /// - Parameter secureLevel: The security level determining which storage backend to clear.
    /// - Returns: `.success(true)` when all data is successfully removed, or
    ///   `.failure(LocalStorageErrorType)` for authentication or system errors.
    func deleteAll(secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>
}

// sourcery:end

/// Extension protocol providing JSON serialization capabilities for complex objects.
///
/// This protocol extends the base storage functionality to support storing and retrieving
/// complex Swift objects that conform to `Codable`. This enables the LocalStorage system
/// to handle structured data, custom types, and complex object graphs while maintaining
/// the same security model and error handling approach.
///
/// ## Implementation Note
/// This is separated from the main protocol to work around Sourcery limitations with
/// generic methods. The actual implementation should combine both protocols for a
/// complete storage interface.
///
/// ## JSON Serialization Process
/// 1. **Writing**: Objects are encoded to JSON using `JSONEncoder`
/// 2. **Storage**: JSON data is stored as binary data in the chosen backend
/// 3. **Reading**: Binary data is retrieved and decoded using `JSONDecoder`
/// 4. **Type Safety**: Swift's generic system ensures type-safe retrieval
///
/// ## Usage Example
/// ```swift
/// struct User: Codable {
///     let id: String
///     let name: String
/// }
///
/// let user = User(id: "123", name: "John")
/// await repository.writeJSON(key: "current_user", value: user, secureLevel: .medium)
///
/// let retrievedUser: User = try await repository.readJSON(key: "current_user", secureLevel: .medium).get()
/// ```
protocol LocalStorageRepositoryJSONProtocol {
    // MARK: - JSON Write Operations

    // Sourcery can't generate a valid ``ReturnValue`` property for generic method. Skip these methods.
    // sourcery: skip
    /// Stores a JSON-serializable object in local storage with the specified security level.
    ///
    /// The object must conform to `Codable` to ensure it can be both encoded for storage
    /// and decoded when retrieved. The object will be serialized to JSON using `JSONEncoder`
    /// with default settings before being stored in the appropriate backend.
    ///
    /// ## Type Requirements
    /// - The value must conform to `Codable` (both `Encodable` and `Decodable`)
    /// - All nested properties must also be `Codable`
    /// - Circular references are not supported and will cause encoding to fail
    ///
    /// ## JSON Encoding Process
    /// 1. Object is encoded to JSON using `JSONEncoder()`
    /// 2. JSON data is converted to binary `Data`
    /// 3. Binary data is stored using the security level's storage backend
    /// 4. Any encoding failures return `.failure(.typeMismatch)`
    ///
    /// ## Security Routing
    /// - `.low` → UserDefaults (immediate storage, unencrypted JSON)
    /// - `.medium` → Keychain (encrypted storage)
    /// - `.high` → Keychain with authentication prompt
    ///
    /// - Parameters:
    ///   - key: A unique string identifier for this object. Must not be empty.
    ///   - value: The `Codable` object to serialize and store.
    ///   - secureLevel: Determines the storage backend and security measures applied.
    /// - Returns: `.success(true)` on successful encoding and storage, or
    ///   `.failure(LocalStorageErrorType)` for encoding failures or storage errors.
    func writeJSON(key: String, value: some Codable, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>

    // MARK: - JSON Read Operations

    // Sourcery can't generate a valid ``ReturnValue`` property for generic method. Skip these methods.
    // sourcery: skip
    /// Retrieves and deserializes a JSON-stored object from local storage.
    ///
    /// This method retrieves binary data from the appropriate storage backend and
    /// deserializes it back to the specified Swift type using `JSONDecoder`. The type
    /// must match exactly what was originally stored, or decoding will fail.
    ///
    /// ## Type Safety
    /// Swift's generic system ensures compile-time type safety. The return type is
    /// inferred from usage context or can be explicitly specified:
    /// ```swift
    /// let user: User = try await repository.readJSON(key: "user", secureLevel: .medium).get()
    /// // or
    /// let result = await repository.readJSON<User>(key: "user", secureLevel: .medium)
    /// ```
    ///
    /// ## JSON Decoding Process
    /// 1. Binary data is retrieved from the storage backend
    /// 2. Data is decoded from JSON using `JSONDecoder()`
    /// 3. JSON is deserialized to the specified Swift type
    /// 4. Type-safe object is returned to the caller
    ///
    /// ## Security Routing
    /// The security level determines which storage backend is queried and what
    /// authentication (if any) is required to access the data.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the stored object.
    ///   - secureLevel: Determines the storage backend to query and authentication required.
    /// - Returns: `.success(T)` with the deserialized object, or `.failure(LocalStorageErrorType)`
    ///   for missing keys, decoding failures, or authentication errors.
    func readJSON<T>(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable
}
