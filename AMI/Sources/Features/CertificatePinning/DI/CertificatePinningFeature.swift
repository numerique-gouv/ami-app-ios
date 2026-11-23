//
//  CertificatePinningFeature.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

/// Certificate pinning entry point: decides, for a server-trust auth
/// challenge (web view or URLSession), whether the server's certificate
/// chain satisfies the host's pin rules.
///
/// Pinning layers on top of system validation, never replaces it:
/// hosts without a matching pin rule fall through to
/// `.performDefaultHandling`, and any evaluation error on a pinned host
/// fails closed (`.cancelAuthenticationChallenge`).
final class CertificatePinningFeature: Sendable {
    private let evaluator: ServerTrustEvaluator

    init(pinRules: [PinRule]) {
        evaluator = ServerTrustEvaluator(pinRules: pinRules)
    }

    /// Resolves a URL auth challenge against the pin rules.
    ///
    /// Host contract: forward every `URLAuthenticationChallenge` here
    /// (from a web view navigation delegate or a `URLSession` delegate)
    /// and pass the returned pair straight to the delegate completion.
    /// The host is taken from the challenge's protection space — the
    /// connection actually challenged (page or subresource), never the
    /// web view's current URL.
    ///
    /// - Returns: `.useCredential` with the evaluated trust when the chain
    ///   validates and a pin matches; `.performDefaultHandling` for
    ///   non-server-trust challenges, a missing `SecTrust`, or unpinned
    ///   hosts; `.cancelAuthenticationChallenge` when a pinned host's
    ///   chain or pinning check fails.
    func evaluate(challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            return (.performDefaultHandling, .none)
        }

        guard let serverTrust = protectionSpace.serverTrust else {
            return (.performDefaultHandling, .none)
        }

        do {
            if try await evaluator.evaluate(serverTrust, forHost: challenge.protectionSpace.host.lowercased()) {
                // The server certificate chain was successfully verified against a pinned certificate.
                // No need to apply the standard validation by returning `(.performDefaultHandling, .none)`
                // because we already performed the complete system evaluation.
                return (.useCredential, URLCredential(trust: serverTrust))
            } else {
                // The host has no pinned certificate to verify against. Continue navigation normally.
                return (.performDefaultHandling, .none)
            }
        } catch {
            // An evaluation error arose during validation of the server certificate chain
            // against a pinned certificate.
            AppLog.viewModel.error("\(AppLog.logHeader(self)) Server Trust evaluation failed: \(error)")
            return (.cancelAuthenticationChallenge, .none)
        }
    }
}
