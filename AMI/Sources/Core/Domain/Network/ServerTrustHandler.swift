//
//  ServerTrustHandler.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 25/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Decides, for a URL auth challenge, whether the connection may proceed.
///
/// The returned pair is passed verbatim to the session's challenge
/// completion: it is the final decision for that challenge. Implementations
/// must never weaken default system validation, and must fail closed for
/// the hosts they are responsible for.
nonisolated protocol ServerTrustHandler {
    /// Evaluates the challenge and returns the disposition + credential the session must use.
    func evaluate(challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?)
}
