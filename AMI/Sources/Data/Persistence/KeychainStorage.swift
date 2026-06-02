//
//  KeychainStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import KeychainAccess

struct KeychainStorage {
    typealias KeyType = String

    private let store: Keychain

    init() {
        store = Keychain(service: AppBundle.identifier())
    }

    func writeData(_ value: Data, forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) {
        store[data: key] = value
    }

    func readData(forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) -> Data? {
        store[data: key]
    }

    func deleteData(forKey key: KeyType, secureLevel: LocalStorageSecureLevelType) {
        store[data: key] = nil
    }
}

extension KeychainStorage: CustomDebugStringConvertible {
    var debugDescription: String {
        store.debugDescription
    }
}
