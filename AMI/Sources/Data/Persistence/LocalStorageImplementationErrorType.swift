//
//  LocalStorageImplementationErrorType.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 10/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Implementation-specific error definitions for local storage backends.
///
/// This struct provides standardized error instances that can be used across different
/// storage implementations (UserDefaults, Keychain, etc.) as associated values with
/// `LocalStorageErrorType.typeMismatch`. These errors help provide consistent error
/// reporting when storage operations fail due to data type issues or implementation
/// constraints.
enum LocalStorageImplementationErrorType {
    /// Error codes for implementation-specific storage errors.
    private enum ErrorCode: Int {
        case valueTypeIsNotData = 100
    }

    /// Static error representing when a stored value is not of type Data.
    ///
    /// This error occurs when:
    /// - UserDefaults returns a value that cannot be cast to Data type
    /// - Keychain returns data in an unexpected format
    /// - Storage backend corruption prevents proper data retrieval
    /// - Type conversion fails during read operations
    ///
    /// ## Usage
    /// Used as an associated value with `LocalStorageErrorType.typeMismatch`:
    /// ```swift
    /// .failure(.typeMismatch(LocalStorageImplementationErrorType.valueTypeIsNotData))
    /// ```
    ///
    /// ## Error Details
    /// - **Domain**: `{AppBundleID}.LocalStorage.ValueTypeError`
    /// - **Code**: 100
    /// - **Description**: "The stored value is not of type Data"
    /// - **Failure Reason**: "Storage backend returned a value that cannot be cast to Data type"
    static let valueTypeIsNotData = NSError(
        domain: "\(AppBundle.identifier()).LocalStorage.ValueTypeError",
        code: ErrorCode.valueTypeIsNotData.rawValue,
        userInfo: [
            NSLocalizedDescriptionKey: "The stored value is not of type Data",
            NSLocalizedFailureReasonErrorKey: "Storage backend returned a value that cannot be cast to Data type",
        ]
    )
}
