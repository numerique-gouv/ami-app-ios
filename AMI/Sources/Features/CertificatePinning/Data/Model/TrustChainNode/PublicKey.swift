//
//  PublicKey.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

struct PublicKey: TrustChainNode, Sendable {
    let data: Data

    private init(data: Data) {
        self.data = data
    }

    static func extracted(from certificate: SecCertificate) -> Self? {
        guard let key = SecCertificateCopyKey(certificate) else { return nil }
        guard let data = SecKeyCopyExternalRepresentation(key, nil) else { return nil }
        return .init(data: data as Data)
    }
}

extension PublicKey {
    init?(from key: RSA.Signing.PublicKey) {
        guard let data = key.pkcs1Representation else { return nil }
        self.data = data
    }

    init(from key: P256.Signing.PublicKey) {
        data = key.x963Representation
    }

    init(from key: P384.Signing.PublicKey) {
        data = key.x963Representation
    }

    init(from key: P521.Signing.PublicKey) {
        data = key.x963Representation
    }

    /// Creates a pin from any key material conforming to `DERRepresentable`,
    /// so RSA and EC keys can be mixed in the same pinset source array.
    init?(from key: any DERRepresentable) {
        switch key {
        case let key as RSA.Signing.PublicKey: self.init(from: key)
        case let key as P256.Signing.PublicKey: self.init(from: key)
        case let key as P384.Signing.PublicKey: self.init(from: key)
        case let key as P521.Signing.PublicKey: self.init(from: key)
        default: return nil
        }
    }

    /// Convenience initializer with optional key.
    /// Example use: `PublicKey(from: P256.Signing.PublicKey(base64Encoded: base64Representation))`
    init?(from key: (any DERRepresentable)?) {
        guard let key else {
            return nil
        }
        self.init(from: key)
    }
}
