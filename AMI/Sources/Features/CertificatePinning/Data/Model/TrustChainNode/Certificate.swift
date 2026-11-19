//
//  Certificate.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Trust chain node holding the certificate's full DER — a
/// whole-certificate pin: strongest match, but does not survive
/// re-issuance.
struct Certificate: TrustChainNode, Sendable {
    let data: Data

    private init(data: Data) {
        self.data = data
    }

    static func extracted(from certificate: SecCertificate) -> Self? {
        let data = SecCertificateCopyData(certificate) as Data
        return .init(data: data)
    }
}

extension Certificate {
    /// Creates a pin from the base64 of a full X.509 DER; nil when malformed.
    init?(base64Encoded base64String: String) {
        guard let data = Data(base64Encoded: base64String) else { return nil }
        guard SecCertificateCreateWithData(nil, data as CFData) != nil else { return nil }
        self.data = data
    }
}
