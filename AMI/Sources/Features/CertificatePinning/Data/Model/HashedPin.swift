//
//  HashedPin.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

/// A trust chain node storing a digest of another node's data — e.g.
/// the SHA-256 of a certificate's SPKI, the classic key-pinning pin.
///
/// Matches a certificate when the digest of its `Node` equals the stored
/// digest; the underlying key material is never exposed.
struct HashedPin<Node: TrustChainNode, Func: HashFunction>: TrustChainNode, Sendable {
    let data: Data

    private init(data: Data) {
        self.data = data
    }

    static func extracted(from certificate: SecCertificate) -> Self? {
        guard let node = Node.extracted(from: certificate) else { return nil }
        let data = Data(Func.hash(data: node.data))
        return .init(data: data)
    }
}

extension HashedPin {
    /// Creates a pin from the base64 of a raw digest;
    /// nil unless it decodes to exactly `Func.Digest.byteCount` bytes.
    init?(base64Encoded base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        guard data.count == Func.Digest.byteCount else { return nil }
        self.data = data
    }
}
