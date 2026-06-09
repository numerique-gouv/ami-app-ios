//
//  UserDefaultsStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A storage implementation using UserDefaults for persisting non-sensitive binary data.
/// This struct provides a simple key-value interface for storing data that doesn't require
/// encryption or special security measures. Data is stored in the app's UserDefaults domain
/// and persists across app launches.
///
/// ## Use Cases
/// - Application preferences and settings
/// - User interface state
/// - Non-sensitive configuration data
/// - Cached data that can be safely exposed
///
/// ## Security Considerations
/// Data stored through this struct is not encrypted and can be read by anyone with access
/// to the device's file system or backup files. Never use this for sensitive information
/// such as passwords, tokens, or personal data.
///
/// ## Usage
/// ```swift
/// let storage = UserDefaultsStorage(for: "userPreferences")
/// let data = "preference value".data(using: .utf8)!
/// await storage.writeData(data, forKey: "user_preference")
/// ```
struct UserDefaultsStorage {
    /// The key type used to identify stored values.
    typealias KeyType = String

    /// The underlying `UserDefaults` instance used for persistence.
    private let store: UserDefaults

    private let currentUserStoreID: String

    /// Creates a new UserDefaultsStorage instance with the specified user store identifier.
    /// This allows for flexible storage targeting different UserDefaults domains
    /// such as user-specific stores, feature-specific namespaces, or test-specific stores.
    ///
    /// - Parameter userStoreID: A unique identifier for the UserDefaults suite.
    ///   This will be combined with the app bundle identifier to create a unique suite name.
    ///   Should be descriptive of the storage purpose (e.g., "userPreferences", "cache").
    ///
    /// - Note: Initialization can fail in the following situations:
    ///    - userStoreID is an empty string
    ///    - userStoreID exactly matches your bundle ID (conflicts with the standard default database)
    ///    - userStoreID starts with `group.` but:
    ///      - the application doesn't embed the correct entitlement
    ///      - the entitlement exists but the suite name doesn't exactly match the registered group identifier
    ///      - the App Group isn't enabled in your Apple Developer Portal for your App Bundle ID
    init(for userStoreID: String) {
        let currentUserStoreID = "\(AppBundle.identifier()).\(userStoreID)"
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
                .failure(.typeMismatch)
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
