//
//  LocalStorageErrorType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Comprehensive error types that can occur during local storage operations.
/// These errors cover all aspects of the storage system including access failures,
/// authentication issues, and hardware limitations.
enum LocalStorageErrorType: Error, Equatable {
    /// The requested key does not exist in the storage backend.
    /// This error is returned when attempting to read a value that was never stored.
    case keyNotFound

    /// Type conversion or data encoding/decoding failed.
    /// This occurs when the stored data cannot be converted to the expected type,
    /// or when JSON encoding/decoding fails.
    case typeMismatch

    /// User authentication was attempted but failed.
    /// This happens when biometric authentication or passcode entry fails.
    case authenticationFailed

    /// User cancelled the authentication process.
    /// This occurs when the user dismisses the authentication prompt.
    case authenticationCancelled

    /// No biometric authentication is enrolled on the device.
    /// This indicates the user has not set up Face ID, Touch ID, or equivalent.
    case biometryNotEnrolled

    /// Biometric sensor is unavailable or locked.
    /// This occurs when biometrics are disabled or locked due to too many failed attempts.
    case biometryNotAvailable

    case biometryLockout

    case passcodeNotSet

    /// The device's secure hardware (Secure Enclave) is unavailable.
    /// This indicates a hardware-level security issue.
    case secureHardwareUnavailable

    /// The requested storage operation is not supported.
    /// This indicates a protocol method that hasn't been implemented.
    case storageMethodNotFound

    /// An unspecified error occurred during storage operations.
    /// Used as a fallback for unexpected errors with the underlying error attached.
    case unknownError(Error?)
}

// Define Equatable for Error
public extension Equatable where Self: Error {
    static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsError = lhs as NSError
        let rhsError = rhs as NSError
        return lhsError.domain == rhsError.domain && lhsError.code == rhsError.code
    }
}
