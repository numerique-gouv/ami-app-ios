//
//  LocalStorageErrorType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Comprehensive error types that can occur during local storage operations across the Data layer.
///
/// This enum provides unified error handling for all storage backends including UserDefaults (low security)
/// and Keychain (medium/high security). These errors are used throughout the LocalStorage system to provide
/// consistent error reporting from the Data layer to the Domain layer.
///
/// ## Error Categories
/// - **Data Access**: `keyNotFound`, `typeMismatch`
/// - **Authentication**: `authenticationFailed`, `authenticationCancelled`, `biometryNotEnrolled`, `biometryNotAvailable`
/// - **System State**: `deviceIsLocked`, `passcodeNotSet`, `secureHardwareUnavailable`, `tooManyAttemps`
/// - **Storage**: `dataIsTooLarge`
/// - **Fallback**: `unknownError`
///
/// ## Usage
/// All LocalStorage operations return `Result<T, LocalStorageErrorType>` to provide explicit error handling
/// and enable the Domain layer to respond appropriately to different failure scenarios.
enum LocalStorageErrorType: Error, Equatable {
    /// The requested key does not exist in the storage backend.
    ///
    /// This error occurs when attempting to read a value that was never stored in either
    /// UserDefaults or Keychain. The Domain layer should treat this as expected behavior
    /// for optional data and provide appropriate default values.
    ///
    /// **Storage Sources**: UserDefaults, Keychain
    case keyNotFound

    /// Type conversion or data encoding/decoding failed during storage operations.
    ///
    /// This error occurs in several scenarios:
    /// - JSON encoding fails when storing `Codable` objects
    /// - JSON decoding fails when retrieving stored objects
    /// - UserDefaults returns data of an unexpected type
    /// - Data corruption prevents proper deserialization
    ///
    /// **Storage Sources**: UserDefaults, Keychain
    ///
    /// - Parameter Error?: The underlying encoding/decoding error for debugging purposes.
    case typeMismatch(Error?)

    /// User authentication was attempted but failed due to incorrect biometric data or passcode.
    ///
    /// This occurs when:
    /// - Face ID/Touch ID fails to recognize the user after multiple attempts
    /// - User enters an incorrect passcode
    /// - Biometric authentication fails due to environmental factors
    ///
    /// The Domain layer should allow retry or fallback to alternative authentication.
    ///
    /// **Storage Sources**: Keychain (high/medium security levels)
    case authenticationFailed

    /// User explicitly cancelled the authentication process.
    ///
    /// This occurs when:
    /// - User taps "Cancel" on the biometric authentication prompt
    /// - System cancels authentication due to app backgrounding
    /// - User dismisses the passcode entry screen
    ///
    /// The Domain layer should respect this decision and not retry automatically.
    ///
    /// **Storage Sources**: Keychain (high/medium security levels)
    case authenticationCancelled

    /// No biometric authentication methods are enrolled on the device.
    ///
    /// This indicates:
    /// - Face ID/Touch ID has never been set up
    /// - All enrolled biometrics have been removed
    /// - Device doesn't support biometric authentication
    ///
    /// The Domain layer should guide users to device settings or use passcode fallback.
    ///
    /// **Storage Sources**: Keychain (high security level)
    case biometryNotEnrolled

    /// Biometric sensor hardware is temporarily unavailable or disabled.
    ///
    /// This occurs when:
    /// - Hardware sensor is malfunctioning
    /// - Biometrics are disabled in device settings
    /// - System has disabled biometrics due to repeated failures
    ///
    /// The Domain layer should attempt passcode fallback or retry later.
    ///
    /// **Storage Sources**: Keychain (high security level)
    case biometryNotAvailable

    /// Too many failed authentication attempts have temporarily locked biometric access.
    ///
    /// This security measure prevents brute force attacks by disabling biometric authentication
    /// after repeated failures. Users must unlock with passcode to re-enable biometrics.
    ///
    /// The Domain layer should guide users to use their device passcode instead.
    ///
    /// **Storage Sources**: Keychain (high security level)
    case tooManyAttemps

    /// The device is currently locked and data access is restricted.
    ///
    /// This occurs when:
    /// - Device is in a locked state and data requires first unlock
    /// - App is running in background without user authentication
    /// - System has restricted access due to security policies
    ///
    /// The Domain layer should wait for device unlock or request user interaction.
    ///
    /// **Storage Sources**: Keychain (all security levels)
    case deviceIsLocked

    /// No device passcode is configured, but secure storage requires it.
    ///
    /// This occurs when attempting to use Keychain storage on devices without a passcode.
    /// The system requires a passcode as the fallback authentication method for Keychain access.
    ///
    /// The Domain layer should guide users to set up device security in Settings.
    ///
    /// **Storage Sources**: Keychain (all security levels)
    case passcodeNotSet

    /// The device's secure hardware (Secure Enclave) is unavailable or malfunctioning.
    ///
    /// This indicates a hardware-level security issue where:
    /// - Secure Enclave chip is not responding
    /// - Security subsystem has encountered an error
    /// - Device security state is compromised
    ///
    /// The Domain layer should fall back to less secure alternatives or show error to user.
    ///
    /// **Storage Sources**: Keychain (all security levels)
    case secureHardwareUnavailable

    /// The data being stored exceeds the storage backend's size limits.
    ///
    /// This occurs when:
    /// - Keychain item exceeds maximum size (typically 4KB)
    /// - UserDefaults data is unreasonably large
    /// - JSON serialization produces oversized data
    ///
    /// The Domain layer should split large data or use alternative storage methods.
    ///
    /// **Storage Sources**: Primarily Keychain, occasionally UserDefaults
    case dataIsTooLarge

    /// An unspecified error occurred during storage operations.
    ///
    /// This is a fallback case for unexpected errors that don't match other categories.
    /// The associated error contains the original system error for debugging purposes.
    ///
    /// The Domain layer should log the error details and provide generic error handling.
    ///
    /// **Storage Sources**: All storage backends
    ///
    /// - Parameter Error?: The underlying system error that caused this failure.
    case unknownError(Error?)
}

/// Extension to provide `Equatable` conformance for Error types.
///
/// This extension enables comparison of `LocalStorageErrorType` values by comparing
/// the underlying `NSError` domain and code. This is essential for unit testing
/// and error handling logic throughout the LocalStorage system.
///
/// ## Implementation Details
/// Errors are considered equal if their `NSError` representations have:
/// - Identical error domains
/// - Identical error codes
///
/// ## Usage in Testing
/// ```swift
/// let error1: LocalStorageErrorType = .keyNotFound
/// let error2: LocalStorageErrorType = .keyNotFound
/// XCTAssertEqual(error1, error2) // This works thanks to this extension
/// ```
///
/// ## Limitations
/// - Associated values in `.unknownError(Error?)` are not compared
/// - Custom error types may not compare accurately across different instances
/// - This approach works best for system-defined error types
public extension Equatable where Self: Error {
    /// Compares two Error instances by their NSError representation.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side error to compare.
    ///   - rhs: The right-hand side error to compare.
    /// - Returns: `true` if both errors have the same domain and code, `false` otherwise.
    static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsError = lhs as NSError
        let rhsError = rhs as NSError
        return lhsError.domain == rhsError.domain && lhsError.code == rhsError.code
    }
}
