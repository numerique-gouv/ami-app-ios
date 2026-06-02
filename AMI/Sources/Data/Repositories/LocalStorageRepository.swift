//
//  LocalStorageRepository.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct LocalStorageRepository {
    private let unprotectedStorage: UserDefaultsStorage
    private let protectedStorage: KeychainStorage

    init() {
        unprotectedStorage = UserDefaultsStorage(store: .standard)
        protectedStorage = KeychainStorage()
    }
}

extension LocalStorageRepository: LocalStorageRepositoryProtocol {
    private func writeData(key: String, value: Data, secureLevel: LocalStorageSecureLevelType) -> Result<Bool, LocalStorageErrorType> {
        switch secureLevel {
        case .low: unprotectedStorage.writeData(value, forKey: key)
        case .medium: protectedStorage.writeData(value, forKey: key, secureLevel: .medium)
        case .high: protectedStorage.writeData(value, forKey: key, secureLevel: .high)
        }
        return .success(true)
    }

    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        switch value.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

    func writeJSON(key: String, value: some Encodable, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        guard let codableValue = value as? Codable else {
            // TODO: better error generation
            return .failure(.typeMismatch(NSError()))
        }
        return switch codableValue.toData {
        case let .failure(error): .failure(.typeMismatch(error))
        case let .success(data): writeData(key: key, value: data, secureLevel: secureLevel)
        }
    }

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

    private func decodeData<T>(_ type: T.Type = T.self, data: Data) -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        do {
            return try .success(JSONDecoder().decode(T.self, from: data))
        } catch {
            return .failure(.typeMismatch(error))
        }
    }

    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        readDataAsType(Bool.self, key: key, secureLevel: secureLevel)
    }

    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType> {
        readDataAsType(Int.self, key: key, secureLevel: secureLevel)
    }

    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType> {
        readDataAsType(String.self, key: key, secureLevel: secureLevel)
    }

    func readJSON<T>(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<T, LocalStorageErrorType>
        where T: Decodable {
        readDataAsType(T.self, key: key, secureLevel: secureLevel)
    }

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
    var toData: Result<Data, Error> {
        do {
            return try .success(JSONEncoder().encode(self))
        } catch {
            return .failure(error)
        }
    }
}
