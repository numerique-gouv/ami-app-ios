//
//  CertificatePinningError.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Errors thrown while validating a pinned server trust.
enum CertificatePinningError: Error, Sendable {
    /// The SSL (hostname) policy could not be attached to the trust.
    case setPolicyFailed
    /// The chain failed system validation (expired, unknown CA, hostname mismatch…).
    case evaluateCertificateChainFailed(host: String, error: Error?)
    /// The chain could not be copied out of the validated trust.
    case copyCertificateChainFailed
    /// The chain validates but no pin matched any certificate in it;
    /// carries the presented chain for diagnostics.
    case pinningFailed(host: String, serverCertificates: [SecCertificate])
}

extension CertificatePinningError: CustomStringConvertible {
    var description: String {
        switch self {
        case .setPolicyFailed: "setPolicyFailed"
        case let .evaluateCertificateChainFailed(host, error): "evaluateCertificateChainFailed for host \"\(host)\" with error \"\(error.debugDescription)\""
        case .copyCertificateChainFailed: "copyCertificateChainFailed"
        case let .pinningFailed(host, serverCertificates):
            "pinningFailed for host \"\(host)\"; presented keys: [\(serverCertificates.compactMap { SecCertificateCopyKey($0)?.description }.joined(separator: ", "))]"
        }
    }
}
