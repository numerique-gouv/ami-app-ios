//
//  SecKey+Description.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// Annotate this extension with @retroactive because it extends a type
// belonging to a framework we don't own.
extension SecKey: @retroactive CustomStringConvertible {
    /// A short human-readable description of the key,
    /// e.g. "RSA 2048-bit" or "EC 256-bit".
    public var description: String {
        let attributes = (SecKeyCopyAttributes(self) as? [CFString: Any]) ?? [:]
        let bits = attributes[kSecAttrKeySizeInBits] as? Int
        let type = attributes[kSecAttrKeyType] as? String
        if type == (kSecAttrKeyTypeRSA as String) {
            return bits.map { "RSA \($0)-bit" } ?? "RSA (size unknown)"
        }
        if type == (kSecAttrKeyTypeECSECPrimeRandom as String) {
            return bits.map { "EC \($0)-bit" } ?? "EC (size unknown)"
        }
        return "unknown key type"
    }
}
