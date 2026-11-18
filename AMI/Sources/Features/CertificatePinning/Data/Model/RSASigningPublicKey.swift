//
//  RSASigningPublicKey.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum RSA {
    enum Signing {
        /// An RSA public key stored as its DER-encoded SubjectPublicKeyInfo.
        ///
        /// Only the `Data` is stored (no `SecKey`), which keeps the struct
        /// trivially `Sendable`: `SecKey` is not `Sendable`, and holding one
        /// would require `@unchecked Sendable` (or worse, a data race risk).
        struct PublicKey: DERRepresentable, Sendable {
            /// The DER-encoded SubjectPublicKeyInfo (SPKI).
            let derRepresentation: Data

            /// The PKCS#1 `RSAPublicKey` bytes, derived on demand from the
            /// stored SPKI. `SecKeyCopyExternalRepresentation` returns PKCS#1
            /// for RSA keys, which is exactly what `PublicKey` pin nodes use.
            var pkcs1Representation: Data? {
                guard let key = try? Self.buildKey(from: derRepresentation) else {
                    return nil
                }
                return SecKeyCopyExternalRepresentation(key, nil) as Data?
            }

            init<Bytes>(derRepresentation: Bytes) throws where Bytes: RandomAccessCollection, Bytes.Element == UInt8 {
                let data = Data(derRepresentation)
                // Validates the DER up front: constructing the key fails for
                // non-SPKI or non-RSA input, so invalid pins never slip into
                // the pinset. The key itself is not retained.
                try _ = Self.buildKey(from: data)
                self.derRepresentation = data
            }

            // Computed (no storage): `CFDictionary` is not `Sendable`, so a
            // stored `static let` would be a non-concurrency-safe global.
            private static var rsaPublicKeyAttributes: CFDictionary {
                [
                    kSecAttrKeyType: kSecAttrKeyTypeRSA,
                    kSecAttrKeyClass: kSecAttrKeyClassPublic,
                ] as CFDictionary
            }

            /// Creates a `SecKey` from SPKI DER, throwing if the input is not a
            /// valid RSA public key — including the NULL-key-without-error edge
            /// case, which is covered by a fallback error.
            private static func buildKey(from data: Data) throws -> SecKey {
                var error: Unmanaged<CFError>?
                guard let key = SecKeyCreateWithData(data as CFData, Self.rsaPublicKeyAttributes, &error) else {
                    guard let error = error?.takeRetainedValue() as? Error else {
                        throw NSError(domain: NSOSStatusErrorDomain, code: .init(errSecCoreFoundationUnknown))
                    }
                    throw error
                }
                return key
            }
        }
    }
}
