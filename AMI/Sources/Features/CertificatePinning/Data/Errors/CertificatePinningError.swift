//
//  CertificatePinningError.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum CertificatePinningError: Error, Sendable {
    case setPolicyFailed
    case evaluateCertificateChainFailed(host: String, error: Error?)
    case copyCertificateChainFailed
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
