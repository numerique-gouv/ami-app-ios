//
//  ServerTrustEvaluating.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated protocol ServerTrustEvaluating {
    /// Evaluate if a certificate pinnng need to be verified.
    /// - Returns:
    ///   true if a pinned certificate is successfully verified,
    ///   false if no pinned certificate is associated with the host
    ///
    /// - Throws: throws an error if any stepin the evaluation
    ///   of the server security chain evaluation failed.
    func evaluate(_ trust: SecTrust, forHost host: String) async throws -> Bool
}
