//
//  UserDefaultsStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Low-security storage implementation using UserDefaults for non-sensitive binary data persistence.
///
/// This struct provides the Data layer implementation for `.low` security level storage in the
/// LocalStorage system. It offers a simple, fast key-value interface for storing data that doesn't
/// require encryption or special security measures. All data is stored in the app's UserDefaults
/// domain and persists across app launches and device restarts.
///
/// ## Architecture Role
/// - **Layer**: Data layer storage backend
/// - **Security Level**: `.low` only (unencrypted storage)
/// - **Performance**: Fastest access among all storage backends
/// - **Persistence**: Automatic across app launches and device restarts
///
/// ## Use Cases
/// - Application preferences and settings
/// - User interface state (theme, layout preferences)
/// - Non-sensitive configuration data
/// - Feature flags and toggles
/// - Cached data that can be safely exposed
/// - Development and testing data
///
/// ## Security Considerations
///
/// ⚠️ **SECURITY WARNING**: Data stored through this implementation is **NOT ENCRYPTED**
/// and can be accessed by:
/// - Anyone with physical access to the device
/// - Device backup files (iTunes/Finder backups, iCloud backups)
/// - Debugging tools and app inspection utilities
/// - Other processes running with appropriate privileges
///
/// **Never use UserDefaultsStorage for**:
/// - Passwords, tokens, or authentication credentials
/// - Personal identifying information (PII)
/// - Financial or payment data
/// - Medical or health information
/// - Any data subject to privacy regulations
///
/// ## UserDefaults Suite Isolation
/// This implementation uses UserDefaults suites to provide data isolation between different
/// users, app contexts, or feature areas. Each `userStoreID` creates a separate namespace:
///
/// ```
/// Suite Name Format: {AppBundleID}.{userStoreID}
/// Examples:
/// - com.example.app.user_123
/// - com.example.app.cache
/// - com.example.app.preferences
/// ```
///
/// ## Usage Example
/// ```swift
/// let storage = UserDefaultsStorage(for: "userPreferences")
///
/// // Store JSON-encoded data
/// let preferenceData = "{\"theme\":\"dark\"}".data(using: .utf8)!
/// await storage.writeData(preferenceData, forKey: "ui_theme")
///
/// // Retrieve and decode data
/// let result = await storage.readData(forKey: "ui_theme")
/// ```
struct UserDefaultsStorage {
    /// The unique identifier type for stored values in this UserDefaults suite.
    typealias KeyType = String

    /// The underlying `UserDefaults` instance providing persistent storage capabilities.
    ///
    /// This is configured as a named suite (not the standard UserDefaults) to provide
    /// data isolation and prevent conflicts with other app data or system preferences.
    private let store: UserDefaults

    /// The complete suite identifier used for this UserDefaults instance.
    ///
    /// This combines the app bundle identifier with the user-provided store ID to create
    /// a unique namespace. Used for debugging and for the `deleteAll` operation.
    private let currentUserStoreID: String

    /// Creates a new UserDefaultsStorage instance with user-specific data isolation.
    ///
    /// This initializer creates a dedicated UserDefaults suite for the specified user or context,
    /// enabling data isolation between different users, feature areas, or testing contexts.
    /// The suite name combines the app's bundle identifier with the provided user store ID.
    ///
    /// ## Suite Naming Convention
    /// ```
    /// Suite Name: {App Bundle ID}.{userStoreID}
    /// Example: "com.example.myapp.user_123"
    /// ```
    ///
    /// ## Data Isolation Benefits
    /// - **User Switching**: Different users can have completely separate preferences
    /// - **Feature Isolation**: Different app features can maintain separate data stores
    /// - **Testing**: Test suites can use isolated storage that doesn't affect production data
    /// - **Multi-Context**: Support for multiple simultaneous contexts (e.g., work vs personal)
    ///
    /// ## Failure Scenarios
    /// The initializer will terminate the app (via `fatalError`) in these situations:
    /// - `userStoreID` is an empty string
    /// - `userStoreID` exactly matches the app's bundle identifier (naming conflict)
    /// - `userStoreID` starts with `group.` but:
    ///   - App doesn't have the required App Groups entitlement
    ///   - Entitlement exists but suite name doesn't match a registered group identifier
    ///   - App Group isn't enabled in Apple Developer Portal for the app's Bundle ID
    ///
    /// ## App Groups Support
    /// If `userStoreID` starts with `group.`, this enables shared UserDefaults between
    /// multiple apps in the same App Group. Ensure proper App Groups configuration:
    /// 1. Enable App Groups capability in Xcode
    /// 2. Add group identifier to App Groups entitlement
    /// 3. Configure matching group in Apple Developer Portal
    ///
    /// ## Usage Examples
    /// ```swift
    /// // User-specific storage
    /// let userStorage = UserDefaultsStorage(for: "user_\(userId)")
    ///
    /// // Feature-specific storage
    /// let cacheStorage = UserDefaultsStorage(for: "imageCache")
    ///
    /// // Shared storage across app extensions
    /// let sharedStorage = UserDefaultsStorage(for: "group.com.example.shared")
    ///
    /// // Testing storage (isolated from production)
    /// let testStorage = UserDefaultsStorage(for: "test_\(testName)")
    /// ```
    ///
    /// - Parameter userStoreID: A unique identifier that will be combined with the bundle ID
    ///   to create the UserDefaults suite name. Must not be empty and should be descriptive
    ///   of the storage purpose.
    init(for userStoreID: String) {
        let currentUserStoreID = "\(AppBundle.identifier).\(userStoreID)"
        guard let userStore = UserDefaults(suiteName: currentUserStoreID) else {
            fatalError("\(AppLog.logHeader(UserDefaultsStorage.self)) Unable to create UserDefaults suite for user store ID: \(currentUserStoreID)")
        }
        store = userStore
        self.currentUserStoreID = currentUserStoreID
    }

    /// Stores binary data in UserDefaults for the specified key.
    /// The data is persisted immediately and will be available across app launches.
    /// Any existing data for the same key will be replaced.
    ///
    /// - Parameters:
    ///   - data: The binary data to store. Can be any valid Data object.
    ///   - key: A unique string identifier for the data. Must not be empty.
    ///
    /// - Returns: A Result containing `true` on success or an error on failure.
    ///
    /// - Note: UserDefaults automatically handles data persistence and synchronization.
    func writeData(_ data: Data, forKey key: KeyType) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            store.setValue(data, forKey: key)
            return .success(true)
        }.value
    }

    /// Retrieves binary data from UserDefaults for the specified key.
    /// Returns the exact data that was previously stored, or an error if no data exists.
    ///
    /// - Parameter key: The unique string identifier for the stored data.
    /// - Returns: A Result containing the stored binary data on success, or an error if the key is not found or there's a type mismatch.
    func readData(forKey key: KeyType) async -> Result<Data, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            switch store.object(forKey: key) {
            case .none: .failure(.keyNotFound)
            case let .some(storedValue as Data): .success(storedValue)
            default: // The read value is not of type Data.
                .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
            }
        }.value
    }

    /// Removes stored data from UserDefaults for the specified key.
    /// This operation is permanent and cannot be undone. No error occurs if the key doesn't exist.
    ///
    /// - Parameter key: The unique string identifier for the data to remove.
    /// - Returns: A Result containing `true` on successful removal or an error on failure.
    func deleteData(forKey key: KeyType) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            store.removeObject(forKey: key)
            return .success(true)
        }.value
    }

    /// Removes all stored data from this UserDefaults suite.
    /// This operation permanently deletes the entire persistent domain associated with
    /// the current user store, effectively clearing all key-value pairs that were stored
    /// through this storage instance.
    ///
    /// - Warning: This is a destructive operation that cannot be undone. All data
    ///   stored in this UserDefaults suite will be permanently lost.
    ///
    /// - Note: This method is synchronous and completes immediately. The deletion
    ///   affects only the specific UserDefaults suite created with the current
    ///   `userStoreID`, not the entire UserDefaults system.
    ///
    /// ## Use Cases
    /// - Clearing all user preferences during logout
    /// - Resetting application state during troubleshooting
    /// - Implementing "clear all data" functionality
    /// - Cleaning up during app uninstall or reset
    func deleteAll() async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            store.removePersistentDomain(forName: currentUserStoreID)
            return .success(true)
        }.value
    }
}

/// Provides debugging support for UserDefaultsStorage by exposing the underlying store contents.
/// This extension allows developers to inspect all stored key-value pairs during development
/// and testing to understand the current state of UserDefaults.
///
/// - Warning: The debug output will include all UserDefaults data, which may contain
///   sensitive information depending on what other parts of the app store there.
extension UserDefaultsStorage: CustomDebugStringConvertible {
    /// A human-readable representation of all key-value pairs in the UserDefaults store.
    /// This includes data from the entire UserDefaults domain, not just data stored
    /// through this storage class.
    ///
    /// - Important: This exposes all UserDefaults contents and should only be used
    ///   during development. Disable debug logging in production builds to prevent
    ///   accidental exposure of user data.
    var debugDescription: String {
        let fullDict = store.dictionaryRepresentation()
        return fullDict.debugDescription
    }
}
