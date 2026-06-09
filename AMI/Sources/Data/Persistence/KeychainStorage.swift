//
//  KeychainStorage.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 02/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import KeychainAccess
import LocalAuthentication

/// A secure storage implementation using the system Keychain for data persistence.
/// This class provides encrypted storage for sensitive data with automatic service scoping
/// based on the app's bundle identifier. All data is securely stored in the iOS/macOS Keychain
/// and can optionally require biometric authentication for access.
///
/// ## Authentication Requirements
/// - `false`: Standard Keychain encryption without biometric protection
/// - `true`: Keychain encryption with biometric/passcode protection (not yet implemented)
///
/// ## Usage
/// ```swift
/// let storage = KeychainStorage()
/// let data = "sensitive data".data(using: .utf8)!
/// storage.writeData(data, forKey: "api_token", requireAuthentication: false)
/// ```
struct KeychainStorage {
    /// The key type used to identify stored values.
    typealias KeyType = String

    /// The underlying `Keychain` instance used for secure persistence.
    private let store: Keychain

    /// The synchronization policy to use for any item stored in Keychain: prevent synchronizatioin through iCloud.
    private let synchronizationPolicy = false
    /// The accessibility policy to use for any item stored in Keychain:
    /// - The data in the keychain item cannot be accessed after a restart until the device has been unlocked once by the user
    /// - Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present.
    private let accessibilityPolicy: Accessibility = .whenPasscodeSetThisDeviceOnly
    /// The authentication policy to use for items stored in Keychain with authentication required.

    private let readAuthenticationContext = LAContext()

    private let authenticationPrompt = "Access to protected data"

    /// Creates a new `KeychainStorage` instance automatically scoped to the app's bundle identifier.
    /// The Keychain service name is set to the app's bundle ID to ensure data isolation
    /// between different applications.
    ///
    /// - Note: Uses `AppBundle.identifier()` to determine the service scope.
    init(for userStoreID: String) {
        store = Keychain(service: "\(AppBundle.identifier()).\(userStoreID)")
    }

    /// Securely stores binary data in the Keychain for the specified key with optional authentication requirement.
    /// The data is encrypted using the system's Keychain encryption mechanisms.
    /// Any existing data for the same key will be overwritten.
    ///
    /// - Parameters:
    ///   - value: The binary data to store securely. Must not be empty.
    ///   - key: A unique string identifier for the data. Must not be empty.
    ///   - requireAuthentication: Whether accessing this data should require biometric/passcode authentication.
    ///
    /// - Note: Authentication requirement with biometric protection is not yet implemented.
    ///   All data currently uses standard Keychain storage regardless of this parameter.
    func writeData(_ data: Data, forKey key: KeyType, requireAuthentication: Bool) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                if requireAuthentication {
                    try store
                        .synchronizable(synchronizationPolicy)
                        .accessibility(accessibilityPolicy)
                        .set(data, key: key, ignoringAttributeSynchronizable: false)
                } else {
                    try store
                        .synchronizable(synchronizationPolicy)
                        .accessibility(accessibilityPolicy)
                        .set(data, key: key, ignoringAttributeSynchronizable: false)
                }
                return Result<Bool, LocalStorageErrorType>.success(true)
            } catch {
                return Result<Bool, LocalStorageErrorType>.failure(.typeMismatch)
            }
        }.value
    }

    /// Retrieves securely stored binary data from the Keychain for the specified key.
    /// The data is automatically decrypted using the system's Keychain mechanisms.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the stored data.
    ///   - requireAuthentication: Whether this data requires biometric/passcode authentication to access.
    /// - Returns: The decrypted binary data if found, or `nil` if no data exists for the key.
    ///
    /// - Note: For data requiring authentication, this method should prompt for biometric/passcode
    ///   authentication, but this is not yet implemented.
    func readData(forKey key: KeyType, requireAuthentication: Bool) async -> Result<Data, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                // If authentication is required to read keychain value, evaluate LAContext policiy.
                if requireAuthentication {
                    var canEvaluatePolicyError: NSError?
                    guard readAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthentication, error: &canEvaluatePolicyError) else {
                        throw canEvaluatePolicyError ?? LocalStorageErrorType.unknownError(nil)
                    }

                    try await readAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: authenticationPrompt)
                }

                if let storedValue = try store.getData(key, ignoringAttributeSynchronizable: false) {
                    return .success(storedValue)
                } else {
                    return .failure(.keyNotFound)
                }
            } catch let error as LocalStorageErrorType {
                return Result<Data, LocalStorageErrorType>.failure(error)
            } catch let error as LAError {
                switch error.code {
                case .userCancel, .systemCancel, .appCancel:
                    return .failure(.authenticationCancelled)

                    //                case .userFallback:
                    //                    // User wants password — present your own credential UI
                    //                    break

                case .authenticationFailed:
                    // Wrong finger/face repeatedly — inform the user
                    return .failure(.authenticationFailed)

                case .biometryLockout:
                    // Re-attempt with .deviceOwnerAuthentication to let passcode unlock biometry
                    return .failure(.biometryLockout)

                case .biometryNotAvailable:
                    // Hardware state changed mid-session — fall back gracefully
                    return .failure(.biometryNotAvailable)

                case .biometryNotEnrolled:
                    // Hardware state changed mid-session — fall back gracefully
                    return .failure(.biometryNotEnrolled)

                case .passcodeNotSet:
                    return .failure(.passcodeNotSet)

                case .invalidContext:
                    // Create a new LAContext and retry
                    return .failure(.unknownError(error))

                case .notInteractive:
                    // Don't set interactionNotAllowed = true if you need the prompt
                    return .failure(.unknownError(error))

                default:
                    return .failure(.unknownError(error))
                }
            } catch {
                return .failure(.unknownError(error))
            }
        }.value
    }

    /// Permanently removes stored data from the Keychain for the specified key.
    /// This operation is irreversible and will completely delete the encrypted data.
    /// No error is generated if the key doesn't exist.
    ///
    /// - Parameters:
    ///   - key: The unique string identifier for the data to remove.
    ///   - requireAuthentication: Whether removing this data requires biometric/passcode authentication.
    ///
    /// - Note: Authentication requirement for data deletion is not yet implemented.
    ///   Data can currently be deleted regardless of this parameter.
    /// - Important: This operation cannot be undone. Ensure you really want to delete the data.
    func deleteData(forKey key: KeyType, requireAuthentication: Bool) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                try store.remove(key, ignoringAttributeSynchronizable: false)
                return Result<Bool, LocalStorageErrorType>.success(true)
            } catch {
                return Result<Bool, LocalStorageErrorType>.failure(.keyNotFound)
            }
        }.value
    }
}

/// Provides debugging support for KeychainStorage by exposing internal state.
/// This extension allows developers to inspect the contents of the Keychain store
/// during development and testing phases.
///
/// - Warning: The debug description may contain sensitive information and should
///   never be logged or exposed in production builds.
extension KeychainStorage: CustomDebugStringConvertible {
    /// A human-readable representation of the Keychain store's configuration and state.
    /// Delegates to the underlying `Keychain` instance for detailed information.
    ///
    /// - Important: This may contain sensitive debugging information and should only
    ///   be used during development. Ensure debug logs are disabled in production.
    var debugDescription: String {
        store.debugDescription
    }
}
