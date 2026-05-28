//
//  CrossStorageInterface.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 28/05/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum StorageSecureLevelType: String {
    case low
    case medium
    case high
}

enum CrossStorageNativeMethodType: String {
    case storeBool
    case storeInt
    case storeString
    case storeJSON
    case fetchBool
    case fetchInt
    case fetchString
    case fetchJSON
    case deleteBool
    case deleteInt
    case deleteString
    case deleteJSON
}

enum CrossStorageNativeErrorType: Error {
    case keyNotFound
    case typeMismatch
    case writeFailed
    case deleteFailed
    case authenticationRequired
    case authenticationFailed
    case authenticationCancelled
    case biometryNotEnrolled
    case biometryNotAvailable
    case secureHardwareUnavailable
    case encryptionFailed
    case decryptionFailed
    case storageMethodNotFound
    case unknown(Error)
}

enum CrossStorageWebMethodType: String {
    case storeBool
    case storeInt
    case storeString
    case storeJSON
    case fetchBool
    case fetchInt
    case fetchString
    case fetchJSON
    case deleteBool
    case deleteInt
    case deleteString
    case deleteJSON
}

enum CrossStorageWebErrorType: Error {
    case keyNotFound
    case typeMismatch
    case writeFailed
    case deleteFailed
    case storageUnavailable
    case quotaExceeded
    case storageMethodNotFound
    case unknown(Error)
}

protocol CrossStorageNativeProtocol {
    func storeBool(key: String, value: Bool, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func storeInt(key: String, value: Int, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func storeString(key: String, value: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func storeJSON(key: String, value: Any, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>

    func fetchBool(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func fetchInt(key: String, secureLevel: StorageSecureLevelType) -> Result<Int, CrossStorageNativeErrorType>
    func fetchString(key: String, secureLevel: StorageSecureLevelType) -> Result<String, CrossStorageNativeErrorType>
    func fetchJSON(key: String, secureLevel: StorageSecureLevelType) -> Result<Any, CrossStorageNativeErrorType>

    func deleteBool(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func deleteInt(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func deleteString(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
    func deleteJSON(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageNativeErrorType>
}

protocol CrossStorageWebProtocol {
    func storeBool(key: String, value: Bool) -> Result<Bool, CrossStorageWebErrorType>
    func storeInt(key: String, value: Int) -> Result<Bool, CrossStorageWebErrorType>
    func storeString(key: String, value: String) -> Result<Bool, CrossStorageWebErrorType>
    func storeJSON(key: String, value: Any) -> Result<Bool, CrossStorageWebErrorType>

    func fetchBool(key: String) -> Result<Bool, CrossStorageWebErrorType>
    func fetchInt(key: String) -> Result<Int, CrossStorageWebErrorType>
    func fetchString(key: String) -> Result<String, CrossStorageWebErrorType>
    func fetchJSON(key: String) -> Result<Any, CrossStorageWebErrorType>

    func deleteBool(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageWebErrorType>
    func deleteInt(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageWebErrorType>
    func deleteString(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageWebErrorType>
    func deleteJSON(key: String, secureLevel: StorageSecureLevelType) -> Result<Bool, CrossStorageWebErrorType>
}
