//
//  KeychainErrorMapping.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 10/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import KeychainAccess
import LocalAuthentication

/// Error mapping utilities for translating system-level Keychain and authentication errors
/// into the unified `LocalStorageErrorType` hierarchy used throughout the LocalStorage system.
///
/// ## Purpose
/// This extension centralizes the complex logic of mapping platform-specific error codes
/// from two different frameworks (LocalAuthentication and KeychainAccess) into a consistent,
/// application-level error type system. This abstraction enables:
///
/// - **Consistent Error Handling**: All LocalStorage operations return the same error types
/// - **Framework Independence**: Business logic doesn't need to handle platform-specific errors
/// - **Maintainability**: Error mapping logic is centralized and easily updated
/// - **Testing**: Predictable error types enable comprehensive unit testing
/// - **User Experience**: Consistent error messages and recovery flows across the app
///
/// ## Architecture Integration
/// These mapping functions serve as the boundary layer between:
/// - **System Layer**: iOS/macOS security frameworks (LocalAuthentication, Keychain Services)
/// - **Data Layer**: LocalStorage implementation (`KeychainStorage`, `UserDefaultsStorage`)
/// - **Domain Layer**: Business logic that consumes storage operations
///
/// ## Error Categories Handled
///
/// ### LocalAuthentication Errors (LAError)
/// - **User Interaction**: Cancellation, fallback selection, interaction restrictions
/// - **Biometric State**: Availability, enrollment, lockout, hardware disconnection
/// - **Authentication Results**: Success, failure, context validation
/// - **System Configuration**: Passcode requirements, policy enforcement
///
/// ### Keychain Access Errors (Status)
/// - **Data Operations**: Item storage, retrieval, deletion, size limitations
/// - **Access Control**: Authentication requirements, credential validation, permissions
/// - **System State**: Device lock status, hardware availability, service accessibility
/// - **Security Policies**: Entitlement validation, privilege enforcement
///
/// ## Usage Pattern
/// These methods are called internally by `KeychainStorage` operations to provide
/// consistent error reporting across all secure storage operations:
///
/// ```swift
/// catch let error as LAError {
///     return .failure(KeychainStorage.mapLAError(error))
/// } catch let error as Status {
///     return .failure(KeychainStorage.mapKeychainAccessStatus(error))
/// }
/// ```
///
/// ## Error Mapping Strategy
/// The mapping prioritizes user experience and developer clarity:
/// - **Granular Errors**: Specific types for common scenarios (authentication, device state)
/// - **Logical Grouping**: Similar platform errors map to the same LocalStorage error
/// - **Fallback Handling**: Unknown errors preserve original error information
/// - **Context Preservation**: Error details maintained for debugging and logging
///
/// ## Testing Considerations
/// The static nature of these methods enables:
/// - **Unit Testing**: Direct testing of error mapping logic without complex setup
/// - **Mock Scenarios**: Simulation of various system error conditions
/// - **Edge Case Coverage**: Comprehensive testing of unusual error combinations
/// - **Regression Prevention**: Ensures error mapping remains consistent across updates
extension KeychainStorage {
    /// Maps LocalAuthentication framework errors to unified local storage error types.
    ///
    /// This method translates LAError codes from the LocalAuthentication framework into
    /// the standardized `LocalStorageErrorType` hierarchy used throughout the app. It handles
    /// all authentication-related errors that can occur during biometric and passcode operations.
    ///
    /// ## Error Categories Mapped
    ///
    /// ### User Cancellation Scenarios
    /// - **`.userCancel`**: User explicitly dismissed biometric prompt or passcode screen
    /// - **`.systemCancel`**: System cancelled authentication (app backgrounded, incoming call)
    /// - **`.appCancel`**: App programmatically cancelled the authentication request
    /// - **`.userFallback`**: User selected "Use Passcode" or similar fallback option
    /// - **`.notInteractive`**: Authentication required but UI interaction not allowed
    ///
    /// **Maps to**: `LocalStorageErrorType.authenticationCancelled`
    ///
    /// ### Authentication Failures
    /// - **`.authenticationFailed`**: Biometric recognition failed or incorrect passcode entered
    ///
    /// **Maps to**: `LocalStorageErrorType.authenticationFailed`
    ///
    /// ### Biometric System State
    /// - **`.biometryLockout`**: Too many failed attempts, biometrics temporarily disabled
    ///
    /// **Maps to**: `LocalStorageErrorType.tooManyAttemps`
    ///
    /// - **`.biometryNotAvailable`**: Hardware sensor unavailable or disabled in settings
    /// - **`.biometryDisconnected`**: External biometric sensor disconnected (rare)
    ///
    /// **Maps to**: `LocalStorageErrorType.biometryNotAvailable`
    ///
    /// - **`.biometryNotEnrolled`**: No biometric data enrolled on device
    ///
    /// **Maps to**: `LocalStorageErrorType.biometryNotEnrolled`
    ///
    /// ### Device Security Configuration
    /// - **`.passcodeNotSet`**: Device doesn't have a passcode configured
    ///
    /// **Maps to**: `LocalStorageErrorType.passcodeNotSet`
    ///
    /// - **`.invalidContext`**: Authentication context invalid or corrupted
    ///
    /// **Maps to**: `LocalStorageErrorType.secureHardwareUnavailable`
    ///
    /// ### Fallback Handling
    /// - **Unknown LAError codes**: Preserves original error for debugging
    ///
    /// **Maps to**: `LocalStorageErrorType.unknownError(error)`
    ///
    /// ## Usage Context
    /// This method is called whenever LocalAuthentication operations fail during:
    /// - Biometric authentication prompts (Face ID, Touch ID)
    /// - Passcode entry and validation
    /// - Authentication context setup and configuration
    /// - Device capability detection and validation
    ///
    /// ## Error Recovery Guidance
    /// The mapped errors enable appropriate user-facing responses:
    /// - **Cancellation**: Respect user choice, don't retry automatically
    /// - **Failed Authentication**: Allow retry with clear feedback
    /// - **System Issues**: Guide user to device settings or alternative methods
    /// - **Hardware Problems**: Graceful degradation to passcode or alternative flows
    ///
    /// - Parameter error: The LAError from LocalAuthentication framework to be mapped.
    ///   Contains the specific error code and context from the authentication operation.
    /// - Returns: A corresponding `LocalStorageErrorType` that represents the error in
    ///   the unified application error hierarchy.
    ///
    /// - Note: This mapping is designed to be comprehensive but may need updates as
    ///   new LAError codes are introduced in future iOS/macOS versions.
    static func mapLAError(_ error: LAError) -> LocalStorageErrorType {
        switch error.code {
        case .userCancel, .systemCancel, .appCancel:
            .authenticationCancelled

        case .authenticationFailed:
            .authenticationFailed

        case .biometryLockout:
            .tooManyAttemps

        case .biometryNotAvailable:
            .biometryNotAvailable

        case .biometryNotEnrolled:
            .biometryNotEnrolled

        case .passcodeNotSet:
            .passcodeNotSet

        case .userFallback,
             .notInteractive:
            .authenticationCancelled

        case .invalidContext:
            .secureHardwareUnavailable

        case .biometryDisconnected:
            .biometryNotAvailable

        default:
            .unknownError(error)
        }
    }

    /// Maps KeychainAccess Status codes to unified local storage error types.
    ///
    /// This method translates Status error codes from the KeychainAccess framework into
    /// the standardized `LocalStorageErrorType` hierarchy. It handles all Keychain Services
    /// errors that can occur during data storage, retrieval, and management operations.
    ///
    /// ## Error Categories Mapped
    ///
    /// ### Data Not Found
    /// - **`.itemNotFound`**: Requested key doesn't exist in Keychain
    ///
    /// **Maps to**: `LocalStorageErrorType.keyNotFound`
    ///
    /// ### Authentication and Access Control
    /// - **`.authFailed`**: Authentication required but failed
    /// - **`.invalidAccessCredentials`**: Provided credentials invalid or expired
    /// - **`.insufficientCredentials`**: Additional authentication required
    /// - **`.missingEntitlement`**: App lacks required Keychain access entitlements
    /// - **`.noAccessForItem`**: Item exists but access denied
    /// - **`.privilegeNotGranted`**: Insufficient privileges for operation
    /// - **`.privilegeNotSupported`**: Requested privilege level not supported
    ///
    /// **Maps to**: `LocalStorageErrorType.authenticationFailed`
    ///
    /// ### User Cancellation
    /// - **`.userCanceled`**: User explicitly cancelled Keychain operation
    /// - **`.interactionRequired`**: User interaction required but not provided
    ///
    /// **Maps to**: `LocalStorageErrorType.authenticationCancelled`
    ///
    /// ### Device and System State
    /// - **`.interactionNotAllowed`**: UI interaction not allowed in current context
    /// - **`.inDarkWake`**: Device in background mode, some operations restricted
    /// - **`.dataNotAvailable`**: Keychain data unavailable due to device state
    /// - **`.notLoggedIn`**: User not logged into device
    ///
    /// **Maps to**: `LocalStorageErrorType.deviceIsLocked`
    ///
    /// ### Data Size Limitations
    /// - **`.dataTooLarge`**: Data exceeds maximum Keychain item size (~4KB)
    /// - **`.fileTooBig`**: File-based data too large for Keychain storage
    ///
    /// **Maps to**: `LocalStorageErrorType.dataIsTooLarge`
    ///
    /// ### Hardware and Service Availability
    /// - **`.notAvailable`**: Keychain service not available
    /// - **`.deviceFailed`**: Hardware failure or malfunction
    /// - **`.deviceReset`**: Device has been reset, Keychain cleared
    /// - **`.deviceError`**: General device-level error
    /// - **`.deviceVerifyFailed`**: Device verification failed
    /// - **`.serviceNotAvailable`**: Keychain service temporarily unavailable
    ///
    /// **Maps to**: `LocalStorageErrorType.secureHardwareUnavailable`
    ///
    /// ### Fallback Handling
    /// - **Unknown Status codes**: Preserves original error for debugging
    ///
    /// **Maps to**: `LocalStorageErrorType.unknownError(status)`
    ///
    /// ## Usage Context
    /// This method is called whenever Keychain Services operations fail during:
    /// - Data storage (writing new items or updating existing ones)
    /// - Data retrieval (reading stored values)
    /// - Data deletion (removing individual items or bulk operations)
    /// - Service configuration and access control setup
    ///
    /// ## Error Recovery Strategies
    /// The mapped errors enable appropriate application responses:
    /// - **Not Found**: Provide default values or prompt for initial setup
    /// - **Authentication Issues**: Retry with proper credentials or guide to settings
    /// - **Device State**: Wait for unlock or provide alternative storage methods
    /// - **Size Limits**: Split large data or use alternative storage backend
    /// - **Hardware Problems**: Graceful degradation to UserDefaults or error reporting
    ///
    /// ## Platform Considerations
    /// Keychain behavior varies across Apple platforms:
    /// - **iOS**: Full biometric support, device-specific security policies
    /// - **macOS**: Password-based authentication, different accessibility options
    /// - **Simulator**: Limited functionality, some operations may behave differently
    /// - **Testing**: Mock environments may not fully simulate all error conditions
    ///
    /// - Parameter status: The Status error code from KeychainAccess framework to be mapped.
    ///   Represents the specific Keychain Services error that occurred during the operation.
    /// - Returns: A corresponding `LocalStorageErrorType` that represents the error in
    ///   the unified application error hierarchy.
    ///
    /// - Important: Some Status codes may have different meanings depending on the operation
    ///   context. This mapping provides general guidance but specific error handling may
    ///   need additional context-aware logic.
    static func mapKeychainAccessStatus(_ status: Status) -> LocalStorageErrorType {
        switch status {
        case .itemNotFound:
            .keyNotFound

        case .authFailed,
             .invalidAccessCredentials,
             .insufficientCredentials:
            .authenticationFailed

        case .userCanceled:
            .authenticationCancelled

        case .interactionNotAllowed,
             .inDarkWake,
             .dataNotAvailable,
             .notLoggedIn:
            .deviceIsLocked

        case .interactionRequired:
            .authenticationCancelled

        case .dataTooLarge,
             .fileTooBig:
            .dataIsTooLarge

        case .notAvailable,
             .deviceFailed,
             .deviceReset,
             .deviceError,
             .deviceVerifyFailed,
             .serviceNotAvailable:
            .secureHardwareUnavailable

        case .missingEntitlement,
             .noAccessForItem,
             .privilegeNotGranted,
             .privilegeNotSupported:
            .authenticationFailed

        default:
            .unknownError(status)
        }
    }
}
