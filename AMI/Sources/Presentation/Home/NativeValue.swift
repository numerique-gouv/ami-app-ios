//
//  NativeValue.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct NativeValue {
    enum NativeValueMethodType: String {
        case readPrivateBool
        case readPrivateInt
        case readPrivateString
        case readPrivateDecimal

        case readPEncryptedBool
        case readPEncryptedInt
        case readPEncryptedString
        case readPEncryptedDecimal

        case readAuthenticatedBool
        case readAthenticatedInt
        case readAthenticatedString
        case readAthenticatedDecimal

        case writePrivateBool
        case writePrivateInt
        case writePrivateString
        case writePrivateDecimal

        case writePEncryptedBool
        case writePEncryptedInt
        case writePEncryptedString
        case writePEncryptedDecimal

        case writeAuthenticatedBool
        case writeAthenticatedInt
        case writeAthenticatedString
        case writeAthenticatedDecimal

        case deletePrivateBool
        case deletePrivateInt
        case deletePrivateString
        case deletePrivateDecimal

        case deletePEncryptedBool
        case deletePEncryptedInt
        case deletePEncryptedString
        case deletePEncryptedDecimal

        case deleteAuthenticatedBool
        case deleteAthenticatedInt
        case deleteAthenticatedString
        case deleteAthenticatedDecimal

        case existPrivateBool
        case existPrivateInt
        case existPrivateString
        case existPrivateDecimal

        case existPEncryptedBool
        case existPEncryptedInt
        case existPEncryptedString
        case existPEncryptedDecimal

        case existAuthenticatedBool
        case existAthenticatedInt
        case existAthenticatedString
        case existAthenticatedDecimal
    }

    struct NativeValueRequestInput {
        let ID: UUID
        let method: NativeValueMethodType
        let valueID: String
    }

    struct NativeValueRequestOutput {
        let requestID: UUID
        let value: String?
    }

    private let localStorage: LocalStorageRepositoryProtocol

    init(localStorage: LocalStorageRepositoryProtocol) {
        self.localStorage = localStorage
    }
}
