//
//  SecKey+Base64EncodedDER.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

extension SecKey {
    static func fromBase64EncodedDER(_ base64EncodedDER: String) -> SecKey? {
        guard let data = Data(base64Encoded: base64EncodedDER) else { return nil }

        let attributes = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
        ] as CFDictionary

        var error: Unmanaged<CFError>?

        guard let key = SecKeyCreateWithData(data as CFData, attributes, &error) else {
            return nil
        }

        return key
    }
}
