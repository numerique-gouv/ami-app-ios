//
//  ServerTrustEvaluator.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct ServerTrustEvaluator: ServerTrustEvaluating, Sendable {
    private let pinRules: [PinRule]

    init(pinRules: [PinRule]) {
        if pinRules.isEmpty {
            // Application must not start if ServerTrustEvaluator is initialized with a pinRule set empty.
            preconditionFailure("Error creating ServerTrustEvaluator: pin rules set is empty.")
        }
        self.pinRules = pinRules
    }

    func evaluate(_ trust: SecTrust, forHost host: String) async throws(CertificatePinningError) -> Bool {
        // 1. Get the pins for this host.
        let pinsForHost = pinRules.filter { (try? $0.pattern.regex.wholeMatch(in: host)) != nil }.flatMap(\.pins)

        // 2. Check if pinning for the host exists.
        guard !pinsForHost.isEmpty else {
            // Returns false if no pinning exists for this host.
            return false
        }

        // 3. Create a policy object for evaluating server certificate chain and performing
        //    hostname verification.
        let policy = SecPolicyCreateSSL(true, host as CFString)

        // 4. Apply the created policy to the trust management object.
        guard SecTrustSetPolicies(trust, policy) == errSecSuccess else {
            throw .setPolicyFailed
        }

        // 5. Evaluate the server certificate chain against the policy set in step 2.
        var error: CFError?
        guard SecTrustEvaluateWithError(trust, &error) else {
            throw .evaluateCertificateChainFailed(host: host, error: error)
        }

        // 6. Extract the server certificate chain from the trust management object.
        let serverCertificates: [SecCertificate] = SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? []

        guard !serverCertificates.isEmpty else {
            throw .copyCertificateChainFailed
        }

        // 7. Verify that at least one of the trust chain nodes derived from server
        //    certificates is present in our pins list.
        guard pinsForHost.contains(where: { pin in
            // Does the pin matches the certificate present in the tested chain?
            serverCertificates.contains { pin.matches($0) }
        }) else {
            throw .pinningFailed(host: host, serverCertificates: serverCertificates)
        }

        // The server certificate chain was successfully verified against a pinned certificate.
        return true
    }
}
