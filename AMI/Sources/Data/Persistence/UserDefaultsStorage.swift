//
//  UserDefaultsStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct UserDefaultsStorage {
    typealias KeyType = String

    private let store: UserDefaults

    init(store: UserDefaults) {
        self.store = store
    }

    func writeData(_ value: Data, forKey key: KeyType) {
        store.setValue(value, forKey: key)
    }

    func readData(forKey key: KeyType) -> Data? {
        store.data(forKey: key)
    }

    func deleteData(forKey key: KeyType) {
        store.removeObject(forKey: key)
    }
}

extension UserDefaultsStorage: CustomDebugStringConvertible {
    var debugDescription: String {
        let fullDict = store.dictionaryRepresentation()
        return fullDict.debugDescription
    }
}
