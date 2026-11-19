//
//  DERRepresentable.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

/// A type that round-trips through its DER encoding (e.g. keys as SPKI DER).
nonisolated protocol DERRepresentable {
    var derRepresentation: Data { get }
    init<Bytes>(derRepresentation: Bytes) throws where Bytes: RandomAccessCollection, Bytes.Element == UInt8
}

extension DERRepresentable {
    /// Pin-source convenience: base64 of DER, validated; nil when malformed.
    init?(base64Encoded base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        try? self.init(derRepresentation: data)
    }
}

extension P256.Signing.PublicKey: DERRepresentable {}
extension P384.Signing.PublicKey: DERRepresentable {}
extension P521.Signing.PublicKey: DERRepresentable {}
