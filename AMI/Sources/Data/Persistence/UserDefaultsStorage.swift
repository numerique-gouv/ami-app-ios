//
//  UserDefaultsStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A storage abstraction layer over `UserDefaults` that reads and writes raw `Data` values.
/// Provides a simple key-value interface for persisting binary data.
struct UserDefaultsStorage {

    /// The key type used to identify stored values.
    typealias KeyType = String

    /// The underlying `UserDefaults` instance used for persistence.
    private let store: UserDefaults

    /// Creates a new `UserDefaultsStorage` backed by the given `UserDefaults` instance.
    /// - Parameter store: The `UserDefaults` instance to use for storage.
    init(store: UserDefaults) {
        self.store = store
    }

    /// Persists a `Data` value associated with the given key.
    /// Overwrites any existing value stored under the same key.
    /// - Parameters:
    ///   - value: The binary data to store.
    ///   - key: The key under which the data will be saved.
    func writeData(_ value: Data, forKey key: KeyType) {
        store.setValue(value, forKey: key)
    }

    /// Retrieves the `Data` value associated with the given key.
    /// - Parameter key: The key identifying the stored value.
    /// - Returns: The stored `Data`, or `nil` if no value exists for the key.
    func readData(forKey key: KeyType) -> Data? {
        store.data(forKey: key)
    }

    /// Removes the value associated with the given key from the store.
    /// Has no effect if no value exists for the key.
    /// - Parameter key: The key identifying the value to remove.
    func deleteData(forKey key: KeyType) {
        store.removeObject(forKey: key)
    }
}

/// Adds debug support for `UserDefaultsStorage`.
extension UserDefaultsStorage: CustomDebugStringConvertible {

    /// A human-readable representation of the entire `UserDefaults` store,
    /// including all key-value pairs. Useful for debugging.
    var debugDescription: String {
        let fullDict = store.dictionaryRepresentation()
        return fullDict.debugDescription
    }
}
