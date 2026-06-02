//
//  LocalStorageRepository.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

```swift
/// A repository that unifies access to both unprotected and protected local storage.
/// Routes read/write/delete operations to the appropriate storage backend
/// (`UserDefaults` or Keychain) based on the requested security level.
struct LocalStorageRepository {

    /// Storage backend for non-sensitive data, backed by `UserDefaults`.
    private let unprotectedStorage: UserDefaultsStorage

    /// Storage backend for sensitive data, backed by the system Keychain.
    private let protectedStorage: KeychainStorage

    /// Creates a new `LocalStorageRepository` with default storage backends.
    /// - `unprotectedStorage` uses `UserDefaults.standard`.
    /// - `protectedStorage` uses the app-scoped `KeychainStorage`.
    init() {
        unprotectedStorage = UserDefaultsStorage(store: .standard)
        protectedStorage = KeychainStorage()
    }
}

extension LocalStorageRepository: LocalStorageRepositoryProtocol {

    /// Routes a raw `Data` write to the appropriate storage backend based on `secureLevel`.
    /// - `.low` → `UserDefaults`
    /// - `.medium` / `.high` → Keychain
    /// - Parameters:
    ///   - key: The key under which the data will be saved.
    ///   - value: The binary data to persist.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on completion. Never fails at this layer.
    private func writeData(key: String, value: Data, secureLevel: LocalStorageSecureLevelType) -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .low: unprotectedStorage.writeData(value, forKey: key)
        case .medium: protectedStorage.writeData(value, forKey: key, secureLevel: .medium)
        case .high: protectedStorage.writeData(value, forKey: key, secureLevel: .high)
        }
        return .success(true)
    }

    /// Encodes a `Bool` value to `Data` and persists it under the given key.
    /// - Parameters:
    ///   - key: The key under which the value will be saved.
    ///   - value: The boolean value to store.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on success, or `.failure(.typeMismatch)` if encoding fails.
    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
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
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
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
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

    /// Encodes any `Encodable` value as JSON `Data` and persists it under the given key.
    /// The value must also conform to `Codable` — a runtime check is performed.
    /// - Parameters:
    ///   - key: The key under which the value will be saved.
    ///   - value: The `Codable` value to serialize as JSON. It must be `Codable` to be `Decodable` later when reading.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on success, or `.failure(.typeMismatch)` if the value
    ///   is not `Codable` or if JSON encoding fails.
    /// - Note: The `Codable` conformance check should be replaced with a better error in a future iteration.
    func writeJSON(key: String, value: some Codable, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        guard let codableValue = value as? Codable else {
            // TODO: better error generation
            return .failure(.typeMismatch(NSError()))
        }
        return switch codableValue.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

    /// Reads raw `Data` from the appropriate storage backend and decodes it into the expected type `T`.
    /// Routes to `UserDefaults` for `.low` security, or Keychain for `.medium` / `.high`.
    /// - Parameters:
    ///   - type: The `Decodable` type to decode the stored data into.
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(T)` if the key exists and decoding succeeds,
    ///   `.failure(.keyNotFound)` if missing, or `.failure(.typeMismatch)` if decoding fails.
    /// - Note: Biometric/passcode failure handling for `.high` security is not yet implemented.
    private func readDataAsType<T>(_ type: T.Type = T.self, key: String, secureLevel: LocalStorageSecureLevelType) -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        switch secureLevel {
        case .low:
            switch unprotectedStorage.readData(forKey: key) {
            case .none: .failure(.keyNotFound)
            case let .some(data): decodeData(type, data: data)
            }
        case .medium:
            switch protectedStorage.readData(forKey: key, secureLevel: .medium) {
            case .none: .failure(.keyNotFound)
            case let .some(data): decodeData(type, data: data)
            }
        case .high:
            // TODO: handle biometric/passcode failures
            switch protectedStorage.readData(forKey: key, secureLevel: .high) {
            case .none: .failure(.keyNotFound)
            case let .some(data): decodeData(type, data: data)
            }
        }
    }

    /// Attempts to decode raw `Data` into the specified `Decodable` type using `JSONDecoder`.
    /// - Parameters:
    ///   - type: The target `Decodable` type.
    ///   - data: The raw binary data to decode.
    /// - Returns: `.success(T)` if decoding succeeds, or `.failure(.typeMismatch)` if it fails.
    private func decodeData<T>(_ type: T.Type = T.self, data: Data) -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        do {
            return try .success(JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(.typeMismatch(error))
        }
    }

    /// Reads and decodes a `Bool` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(Bool)` or a relevant `.failure`.
    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        readDataAsType(Bool.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes an `Int` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(Int)` or a relevant `.failure`.
    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType> {
        readDataAsType(Int.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes a `String` value stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(String)` or a relevant `.failure`.
    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType> {
        readDataAsType(String.self, key: key, secureLevel: secureLevel)
    }

    /// Reads and decodes a JSON-encoded value of type `T` stored under the given key.
    /// - Parameters:
    ///   - key: The key identifying the stored value.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(T)` if found and decodable, or a relevant `.failure`.
    func readJSON<T>(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        readDataAsType(T.self, key: key, secureLevel: secureLevel)
    }

    /// Deletes the value associated with the given key from the appropriate storage backend.
    /// Routes to `UserDefaults` for `.low` security, or Keychain for `.medium` / `.high`.
    /// - Parameters:
    ///   - key: The key identifying the value to remove.
    ///   - secureLevel: Determines which storage backend is used.
    /// - Returns: `.success(true)` on completion. Does not verify prior key existence.
    /// - Note: Key presence check before deletion is not yet implemented.
    func delete(key: String, secureLevel: LocalStorageSecureLevelType) -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .low:
            // TODO: Should check for key presence?
            unprotectedStorage.deleteData(forKey: key)
            return .success(true)
        case .medium:
            // TODO: Should check for key presence?
            protectedStorage.deleteData(forKey: key, secureLevel: .medium)
            return .success(true)
        case .high:
            // TODO: Should check for key presence?
            protectedStorage.deleteData(forKey: key, secureLevel: .high)
            return .success(true)
        }
    }
}

extension Encodable {
    /// Encodes any `Encodable` value into JSON `Data` using `JSONEncoder`.
    /// Convenience property used throughout the storage layer to serialize values before persisting.
    /// - Returns: `.success(Data)` if encoding succeeds, or `.failure(Error)` if it fails.
    var toData: Result<Data, Error> {
        do {
            return try .success(JSONEncoder().encode(self))
        } catch {
            return .failure(error)
        }
    }
}
```
