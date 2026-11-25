//
//  ServerTrustURLSessionDelegate.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 25/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Session-level auth-challenge router for `ServerTrustURLSession`:
/// forwards every challenge to the injected handler and returns the
/// handler's pair verbatim; with no handler, everything falls back to
/// the system default.
final class ServerTrustURLSessionDelegate: NSObject, Sendable {
    private let handler: URLSessionTrustHandler?

    /// - Parameter handler: the trust decision-maker; `nil` = system default validation only.
    init(handler: URLSessionTrustHandler?) {
        self.handler = handler
    }
}

extension ServerTrustURLSessionDelegate: URLSessionDelegate {
    /// The session calls this for the connection's server trust (and any
    /// other challenge type); the returned pair is the final decision.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        guard let handler else {
            // No trust policy installed: system default validation only.
            return (.performDefaultHandling, nil)
        }

        return await handler.evaluate(challenge: challenge)
    }
}
