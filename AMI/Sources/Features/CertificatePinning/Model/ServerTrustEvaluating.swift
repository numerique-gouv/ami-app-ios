//
//  ServerTrustEvaluating.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated protocol ServerTrustEvaluating {
    /// Evaluates a server trust against the host's pin rules.
    /// - Returns:
    ///   `true` if the chain validates and a pin matches,
    ///   `false` if no pin rule is associated with the host
    ///   (system validation then applies).
    /// - Throws: `CertificatePinningError` if any step of the chain
    ///   validation or pin matching fails.
    func evaluate(_ trust: SecTrust, forHost host: String) async throws -> Bool
}
