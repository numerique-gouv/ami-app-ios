//
//  NativeValue.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct NativeValue {
    enum NativeValueMethodName: String {
        case readPrivateBool
        case readPrivateInt
        case readPrivateString
        case readPrivateDecimal

        case readEncryptedBool
        case readEncryptedInt
        case readEncryptedString
        case readEncryptedDecimal

        case readAuthenticatedBool
        case readAuthenticatedInt
        case readAuthenticatedString
        case readAuthenticatedDecimal

        case writePrivateBool
        case writePrivateInt
        case writePrivateString
        case writePrivateDecimal

        case writeEncryptedBool
        case writeEncryptedInt
        case writeEncryptedString
        case writeEncryptedDecimal

        case writeAuthenticatedBool
        case writeAuthenticatedInt
        case writeAuthenticatedString
        case writeAuthenticatedDecimal

        case deletePrivateBool
        case deletePrivateInt
        case deletePrivateString
        case deletePrivateDecimal

        case deleteEncryptedBool
        case deleteEncryptedInt
        case deleteEncryptedString
        case deleteEncryptedDecimal

        case deleteAuthenticatedBool
        case deleteAuthenticatedInt
        case deleteAuthenticatedString
        case deleteAuthenticatedDecimal

        case existPrivateBool
        case existPrivateInt
        case existPrivateString
        case existPrivateDecimal

        case existEncryptedBool
        case existEncryptedInt
        case existEncryptedString
        case existEncryptedDecimal

        case existAuthenticatedBool
        case existAuthenticatedInt
        case existAuthenticatedString
        case existAuthenticatedDecimal
    }

    enum NativeValueErrorCode: Int {
        case keyNotFound = -1
        case typeMismatch = -2
        case authenticationFailure = -3
        case unexpectedError = 999
    }

    struct NativeValueRequestInput {
        let id: UUID
        let method: NativeValueMethodName
        let valueID: String
    }

    struct NativeValueRequestOutput {
        let requestID: UUID
        let success: Bool
        let value: String?
        let errorCode: Int?
    }

    private let localStorage: LocalStorageRepositoryProtocol

    init(localStorage: LocalStorageRepositoryProtocol) {
        self.localStorage = localStorage
    }
}
