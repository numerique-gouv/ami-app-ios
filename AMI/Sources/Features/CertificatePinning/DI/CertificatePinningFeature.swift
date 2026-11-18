//
//  CertificatePinningFeature.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

final class CertificatePinningFeature: Sendable {
    private let evaluator: ServerTrustEvaluator

    init(pinRules: [PinRule]) {
        evaluator = ServerTrustEvaluator(pinRules: pinRules)
    }

    func evaluate(challenge: URLAuthenticationChallenge, for host: String) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        let protectionSpace = challenge.protectionSpace

        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            return (.performDefaultHandling, .none)
        }

        guard let serverTrust = protectionSpace.serverTrust else {
            return (.performDefaultHandling, .none)
        }

        do {
            if try await evaluator.evaluate(serverTrust, forHost: host) {
                // The server certificate chain was successfully verified against a pinned certificate.
                return (.useCredential, URLCredential(trust: serverTrust))
            } else {
                // The host has no pinned certificate to verify against. Continue navigation normally.
                return (.performDefaultHandling, .none)
            }
        } catch {
            // An error arise during the validation of the server certificate chain
            // against a pinned certificate.
            AppLog.viewModel.error("\(AppLog.logHeader(self)) Server Trust evaluation failed: \(error)")
            return (.cancelAuthenticationChallenge, .none)
        }
    }
}
