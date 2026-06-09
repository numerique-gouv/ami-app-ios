//
//  UserDefaultsStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A storage implementation using UserDefaults for persisting non-sensitive binary data.
/// This class provides a simple key-value interface for storing data that doesn't require
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
/// Data stored through this class is not encrypted and can be read by anyone with access
/// to the device's file system or backup files. Never use this for sensitive information
/// such as passwords, tokens, or personal data.
///
/// ## Usage
/// ```swift
/// let storage = UserDefaultsStorage(store: .standard)
/// let data = "preference value".data(using: .utf8)!
/// storage.writeData(data, forKey: "user_preference")
/// ```
struct UserDefaultsStorage {
    /// The key type used to identify stored values.
    typealias KeyType = String

    /// The underlying `UserDefaults` instance used for persistence.
    private let store: UserDefaults

    /// Creates a new UserDefaultsStorage instance with the specified UserDefaults store.
    /// This allows for flexible storage targeting different UserDefaults domains
    /// such as standard, group containers, or test-specific stores.
    ///
    /// - Parameter store: The UserDefaults instance to use for data persistence.
    ///   Common values include `.standard` for app-wide storage or custom instances
    ///   for group containers or testing isolation.
    init(for userStoreID: String) {
        guard let userStore = UserDefaults(suiteName: "\(AppBundle.identifier()).\(userStoreID)") else {
            fatalError("\(AppLog.logHeader(UserDefaultsStorage.self)) Unable to create UserDefaults store for user \(userStoreID)")
        }
        store = userStore
    }

    /// Stores binary data in UserDefaults for the specified key.
    /// The data is persisted immediately and will be available across app launches.
    /// Any existing data for the same key will be replaced.
    ///
    /// - Parameters:
    ///   - value: The binary data to store. Can be any valid Data object.
    ///   - key: A unique string identifier for the data. Must not be empty.
    ///
    /// - Note: UserDefaults automatically handles data persistence and synchronization.
    func writeData(_ data: Data, forKey key: KeyType) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            store.setValue(data, forKey: key)
            return Result<Bool, LocalStorageErrorType>.success(true)
        }.value
    }

    /// Retrieves binary data from UserDefaults for the specified key.
    /// Returns the exact data that was previously stored, or nil if no data exists.
    ///
    /// - Parameter key: The unique string identifier for the stored data.
    /// - Returns: The stored binary data if found, or `nil` if no data exists for the key.
    func readData(forKey key: KeyType) async -> Result<Data, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            switch store.object(forKey: key) {
            case .none: Result<Data, LocalStorageErrorType>.failure(.keyNotFound)
            case let .some(storedValue as Data): Result<Data, LocalStorageErrorType>.success(storedValue)
            default: Result<Data, LocalStorageErrorType>.failure(.typeMismatch)
            }
        }.value
    }

    /// Removes stored data from UserDefaults for the specified key.
    /// This operation is permanent and cannot be undone. No error occurs if the key doesn't exist.
    ///
    /// - Parameter key: The unique string identifier for the data to remove.
    func deleteData(forKey key: KeyType) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            store.removeObject(forKey: key)
            return Result<Bool, LocalStorageErrorType>.success(true)
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
