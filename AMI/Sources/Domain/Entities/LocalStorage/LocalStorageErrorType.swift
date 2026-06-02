//
//  LocalStorageErrorType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Describes the errors that can occur when storing data locally on the device.
enum LocalStorageErrorType: Error {
    /// The requested key does not exist in the storage.
    case keyNotFound

    /// The type of the stored value does not match the expected type, or the value cannot be converted to the expected type.
    case typeMismatch

    /// Writing to the storage failed (UserDefaults/DataStore or Keychain/KeyStore).
    case writeFailed

    /// Deleting the key from the storage failed.
    case deleteFailed

    /// A biometric or passcode authentication is required but was not presented.
    case authenticationRequired

    /// The biometric or passcode authentication was denied by the user.
    case authenticationFailed

    /// The authentication was cancelled by the user.
    case authenticationCancelled

    /// No biometry is enrolled on the device (no Face ID / Touch ID).
    case biometryNotEnrolled

    /// The biometric sensor is unavailable (disabled, or locked after too many failed attempts).
    case biometryNotAvailable

    /// The secure processor (Secure Enclave) is unavailable.
    case secureHardwareUnavailable

    /// Encrypting the value failed.
    case encryptionFailed

    /// Decrypting the value failed.
    case decryptionFailed

    /// The requested operation does not match any known method of the protocol.
    case storageMethodNotFound

    /// An uncategorized error, with the underlying error as an associated value.
    case unknown(Error)
}
