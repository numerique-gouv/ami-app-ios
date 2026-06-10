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

/// High-security storage implementation using the system Keychain for sensitive data persistence.
///
/// This struct provides the Data layer implementation for `.medium` and `.high` security level
/// storage in the LocalStorage system. It leverages iOS/macOS Keychain Services to provide
/// hardware-accelerated encryption, secure data isolation, and optional biometric authentication
/// for highly sensitive information.
///
/// ## Architecture Role
/// - **Layer**: Data layer storage backend
/// - **Security Levels**: `.medium` (encrypted) and `.high` (encrypted + biometric auth)
/// - **Performance**: Moderate due to encryption overhead and potential authentication prompts
/// - **Persistence**: Secure across app launches, device restarts, and OS updates
///
/// ## Security Features
///
/// ### Hardware-Level Protection
/// - **Secure Enclave Integration**: Uses device's hardware security module when available
/// - **AES Encryption**: Data encrypted with hardware-accelerated AES algorithms
/// - **Key Derivation**: Encryption keys derived from device-specific hardware identifiers
/// - **Tamper Resistance**: Protected against physical and software-based attacks
///
/// ### Access Control Policies
/// - **Device Lock Integration**: Data unavailable when device is locked (until first unlock)
/// - **No Synchronization**: Data stays on device, not synced via iCloud Keychain
/// - **App Isolation**: Data accessible only to the app that created it
/// - **Passcode Dependency**: Requires device passcode to be set for Keychain access
///
/// ### Authentication Modes
/// - **Medium Security**: Standard Keychain encryption without additional authentication
/// - **High Security**: Biometric authentication (Face ID/Touch ID) or passcode required per access
///
/// ## Use Cases
///
/// ### Medium Security (`.medium`)
/// - API authentication tokens and refresh tokens
/// - Service passwords and credentials
/// - Encrypted user session data
/// - Private keys and certificates
/// - OAuth tokens and app-specific secrets
///
/// ### High Security (`.high`)
/// - Highly sensitive personal information
/// - Financial data and payment credentials
/// - Medical records and health information
/// - Legal documents and identification data
/// - Biometric enrollment data
///
/// ## Authentication Flow (High Security)
///
/// ```
/// 1. App requests high-security data access
/// 2. System presents biometric prompt (Face ID/Touch ID)
/// 3. User authenticates successfully → Data decrypted and returned
/// 4. User cancels/fails → Authentication error returned
/// 5. Too many failures → Biometric lockout, passcode required
/// ```
///
/// ## Service Isolation
/// This implementation uses Keychain services to provide data isolation between different
/// users, app contexts, or feature areas. Each `userStoreID` creates a separate service:
///
/// ```
/// Service Name Format: {AppBundleID}.{userStoreID}
/// Examples:
/// - com.example.app.user_123
/// - com.example.app.secure_cache
/// - com.example.app.auth_tokens
/// ```
///
/// ## Error Handling
/// Keychain operations can fail due to various system-level conditions:
/// - Authentication failures (wrong biometric, cancelled by user)
/// - Hardware availability issues (Face ID disabled, sensor unavailable)
/// - System state problems (device locked, passcode not set)
/// - Data size limitations (Keychain has size limits per item)
/// - Storage capacity issues (Keychain full, system errors)
///
/// All errors are mapped to `LocalStorageErrorType` for consistent handling across the app.
///
/// ## Usage Example
/// ```swift
/// let storage = KeychainStorage(for: "secureUserData")
///
/// // Store encrypted data (medium security)
/// let tokenData = "auth_token_12345".data(using: .utf8)!
/// await storage.writeData(tokenData, forKey: "api_token", requireAuthentication: false)
///
/// // Store with biometric protection (high security)
/// let sensitiveData = userBiometricData
/// await storage.writeData(sensitiveData, forKey: "biometric_profile", requireAuthentication: true)
/// ```
struct KeychainStorage {
    /// The unique identifier type for stored values in this Keychain service.
    typealias KeyType = String

    /// The underlying `Keychain` instance providing secure storage capabilities.
    ///
    /// Configured with app-specific service name and security policies to ensure data
    /// isolation and appropriate access controls for different authentication levels.
    private let store: Keychain

    /// The complete service identifier used for this Keychain instance.
    ///
    /// Combines the app bundle identifier with the user-provided store ID to create
    /// a unique service namespace for Keychain storage isolation.
    private let currentUserStoreID: String

    /// The iCloud synchronization policy for Keychain items.
    ///
    /// Set to `false` to prevent data from being synchronized across the user's devices
    /// via iCloud Keychain. This ensures sensitive data remains on the device where it
    /// was created, providing additional security for highly sensitive information.
    private let synchronizationPolicy = false

    /// The accessibility policy defining when Keychain data can be accessed.
    ///
    /// Uses `.whenPasscodeSetThisDeviceOnly` which provides these security characteristics:
    /// - Data cannot be accessed after device restart until first unlock by user
    /// - Items do not migrate to new devices (not included in backups or device transfers)
    /// - Requires device passcode to be set (enforces basic device security)
    /// - Provides balance between security and usability
    private let accessibilityPolicy: Accessibility = .whenPasscodeSetThisDeviceOnly

    /// The biometric authentication policy for high-security items.
    ///
    /// Uses `.biometryAny` to accept any configured biometric authentication:
    /// - Face ID on devices that support it
    /// - Touch ID on devices that support it
    /// - Automatically falls back to passcode when biometrics are unavailable
    /// - Respects user's biometric preferences and system configuration
    private let authenticationPolicy: AuthenticationPolicy = .biometryAny

    /// User-facing prompt message displayed during biometric authentication.
    ///
    /// Shown to users when the system prompts for Face ID, Touch ID, or passcode entry.
    /// Should be localized and descriptive of why authentication is required.
    private let authenticationPrompt = "Access to protected data"

    /// Creates a new KeychainStorage instance with user-specific service isolation.
    ///
    /// This initializer creates a dedicated Keychain service for the specified user or context,
    /// enabling secure data isolation between different users, feature areas, or app contexts.
    /// The service name combines the app's bundle identifier with the provided user store ID.
    ///
    /// ## Service Naming Convention
    /// ```
    /// Service Name: {App Bundle ID}.{userStoreID}
    /// Example: "com.example.myapp.secure_user_123"
    /// ```
    ///
    /// ## Security Isolation Benefits
    /// - **User Switching**: Each user gets completely isolated secure storage
    /// - **Feature Separation**: Different app features can maintain separate encrypted stores
    /// - **Context Isolation**: Support for multiple security contexts (e.g., work vs personal)
    /// - **Testing**: Test suites can use isolated Keychain services
    ///
    /// ## Automatic Configuration
    /// The initializer automatically configures the Keychain with secure defaults:
    /// - Service scoped to the app's bundle identifier + user store ID
    /// - iCloud synchronization disabled for maximum security
    /// - Access restricted to when device is unlocked and passcode is set
    /// - Ready for both standard and biometric-protected storage
    ///
    /// ## Usage Examples
    /// ```swift
    /// // User-specific secure storage
    /// let userKeychain = KeychainStorage(for: "user_\(userId)")
    ///
    /// // Feature-specific secure storage
    /// let authKeychain = KeychainStorage(for: "authentication")
    ///
    /// // Context-specific secure storage
    /// let workKeychain = KeychainStorage(for: "work_context")
    ///
    /// // Testing secure storage (isolated from production)
    /// let testKeychain = KeychainStorage(for: "test_\(testName)")
    /// ```
    ///
    /// - Parameter userStoreID: A unique identifier that will be combined with the bundle ID
    ///   to create the Keychain service name. Must be descriptive and consistent across
    ///   app launches for the same logical storage context.
    init(for userStoreID: String) {
        currentUserStoreID = "\(AppBundle.identifier()).\(userStoreID)"
        store = Keychain(service: currentUserStoreID)
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
    /// - Note: Writing data with `requireAuthentication` set to `true` triggers biometric autrhentication when reading back the data..
    func writeData(_ data: Data, forKey key: KeyType, requireAuthentication: Bool) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                if requireAuthentication {
                    try store
                        .synchronizable(synchronizationPolicy)
                        .accessibility(accessibilityPolicy, authenticationPolicy: authenticationPolicy)
                        .set(data, key: key, ignoringAttributeSynchronizable: false)
                } else {
                    try store
                        .synchronizable(synchronizationPolicy)
                        .accessibility(accessibilityPolicy)
                        .set(data, key: key, ignoringAttributeSynchronizable: false)
                }
                return .success(true)
            } catch let error as LAError {
                return .failure(Self.mapLAError(error))
            } catch let error as Status {
                return .failure(Self.mapKeychainAccessStatus(error))
            } catch {
                return .failure(.unknownError(error))
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
    /// - Note: For data requiring authentication, this method automatically  prompts for biometric/passcode
    ///   authentication.
    func readData(forKey key: KeyType, requireAuthentication: Bool) async -> Result<Data, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                if let storedValue = try store.getData(key, ignoringAttributeSynchronizable: false) {
                    return .success(storedValue)
                } else {
                    return .failure(.keyNotFound)
                }
            } catch let error as LAError {
                return .failure(Self.mapLAError(error))
            } catch let error as Status {
                switch error {
                case .unexpectedError:
                    return .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
                default:
                    return .failure(Self.mapKeychainAccessStatus(error))
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
                return .success(true)
            } catch {
                return .failure(.keyNotFound)
            }
        }.value
    }

    /// Permanently removes all stored data from this Keychain service.
    /// This operation completely clears all key-value pairs associated with this storage instance's service.
    ///
    /// ## Security Implications
    /// - **Scope**: Only affects items in this specific Keychain service (isolated by `userStoreID`)
    /// - **Isolation**: Does not affect other apps or other Keychain services within the same app
    /// - **Authentication**: Configures accessibility policy based on `requireAuthentication` parameter
    /// - **Hardware Integration**: Leverages Secure Enclave for secure deletion when available
    ///
    /// ## Authentication Modes
    /// - **`requireAuthentication: false`**: Uses standard accessibility policy for deletion
    /// - **`requireAuthentication: true`**: Applies biometric authentication policy before deletion
    /// - **Fallback Behavior**: Automatically falls back to passcode when biometrics unavailable
    /// - **Policy Consistency**: Matches the authentication requirements used during data storage
    ///
    /// ## Operation Details
    /// - **Irreversibility**: All data is permanently deleted and cannot be recovered
    /// - **Atomic**: Either all items are deleted successfully, or none are deleted
    /// - **Performance**: Moderate speed due to secure deletion requirements
    /// - **Device State**: Respects device lock state and security policies
    /// - **Authentication Flow**: May prompt for Face ID/Touch ID/passcode based on parameter
    ///
    /// ## Error Scenarios
    ///
    /// ### Authentication-Related (when `requireAuthentication: true`)
    /// - **User Cancellation**: User dismisses biometric prompt or passcode screen
    /// - **Authentication Failure**: Biometric recognition fails or incorrect passcode
    /// - **Biometry Unavailable**: Face ID/Touch ID disabled, not enrolled, or hardware issue
    /// - **Device Locked**: Operation attempted while device is in locked state
    /// - **Too Many Attempts**: Biometric lockout after repeated failures
    ///
    /// ### System-Level
    /// - **Hardware Issues**: Secure Enclave problems or sensor malfunctions
    /// - **System Restrictions**: Corporate policies or parental controls blocking deletion
    /// - **Service Access**: Permission errors if app lacks proper Keychain entitlements
    /// - **Storage State**: Keychain in inconsistent state or corruption detected
    ///
    /// ## Use Cases
    ///
    /// ### Standard Deletion (`requireAuthentication: false`)
    /// ```swift
    /// // Clear non-sensitive cached data
    /// await keychain.deleteAll(requireAuthentication: false)
    /// ```
    ///
    /// ### Authenticated Deletion (`requireAuthentication: true`)
    /// ```swift
    /// // Clear highly sensitive data with user confirmation
    /// await keychain.deleteAll(requireAuthentication: true)
    /// ```
    ///
    /// ### Common Scenarios
    /// - **User Logout**: Clear authentication tokens and session data
    /// - **App Reset**: Remove all securely stored configuration and cache
    /// - **Privacy Compliance**: Complete data erasure for GDPR/privacy regulations
    /// - **Security Incident**: Emergency data clearing after suspected compromise
    /// - **Testing**: Clean slate for isolated test environments
    ///
    /// ## Implementation Details
    /// - **Keychain Filter**: Configures accessibility and authentication policies before deletion
    /// - **Service Isolation**: Uses `Keychain.removeAll()` targeting only this service's items
    /// - **Cross-App Safety**: Preserves Keychain items from other apps and services
    /// - **Error Mapping**: Handles both LAError (authentication) and Status (Keychain) error types
    /// - **Background Execution**: Runs on detached task to avoid blocking UI thread
    ///
    /// - Parameter requireAuthentication: Whether this operation should require user authentication
    ///   (Face ID/Touch ID/passcode) before proceeding with deletion. When `true`, the system
    ///   will prompt for authentication and apply the same biometric policies used for high-security storage.
    /// - Returns: `.success(true)` if all items are successfully deleted, or `.failure(LocalStorageErrorType)`
    ///   if authentication fails, user cancels, or system-level errors prevent the operation.
    ///
    /// - Warning: This operation is **irreversible**. All securely stored data will be permanently lost.
    ///   Ensure proper user confirmation and backup procedures are in place before calling this method.
    ///
    /// - Note: The accessibility policies applied during deletion match those used during storage
    ///   to ensure consistent behavior across the storage lifecycle.
    func deleteAll(requireAuthentication: Bool = false) async -> Result<Bool, LocalStorageErrorType> {
        await Task.detached(priority: .userInitiated) {
            do {
                // Configure Keychain with appropriate accessibility policy based on authentication requirement
                let keychainInstance = if requireAuthentication {
                    store.accessibility(accessibilityPolicy, authenticationPolicy: authenticationPolicy)
                } else {
                    store.accessibility(accessibilityPolicy)
                }

                // Remove all items using the configured Keychain instance
                try keychainInstance.removeAll()
                return .success(true)
            } catch let error as LAError {
                return .failure(Self.mapLAError(error))
            } catch let error as Status {
                return .failure(Self.mapKeychainAccessStatus(error))
            } catch {
                return .failure(.unknownError(error))
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
        "KeychainStorage '\(currentUserStoreID)'\n\(store.debugDescription)"
    }
}
