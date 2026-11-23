//
//  ServerTrustEvaluator.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 16/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Validates a server trust against the pin rules, in strict order:
/// full chain + hostname validation first, then pin matching.
///
/// A broken chain always fails — even when a pin would match — and a
/// validated chain fails closed when no pin matches any of its
/// certificates. `false` (not an error) means the host is not pinned.
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

        // 5. Evaluate the server certificate chain against the SSL policy (steps 3–4).
        //
        // Revocation: this system evaluation applies the system trust
        // policy, and the app adds no separate online check. Apple's
        // Security guide (https://support.apple.com/fr-fr/guide/security/sec100a75d12/web):
        //
        //  - CRT: Certificate Revocation Lists
        //    "On devices with iOS 11 or later and macOS 10.13 or later,
        //     Apple devices are periodically updated with a current list of
        //     revoked and constrained certificates."
        //  - CT: Certificate Transparency
        //    "On devices with iOS 12.1, certificates issued after
        //     October 15, 2018, from a system-trusted root certificate need
        //     to be logged in a trusted Certificate Transparency log to be
        //     allowed for TLS connections."
        //
        // If a stricter LIVE check is ever mandated, add a revocation
        // policy in step 4 (the `as CFArray` cast is required for
        // multiple policies):
        //
        //     guard let revocationPolicy = SecPolicyCreateRevocation(
        //         kSecRevocationOCSPMethod | kSecRevocationRequirePositiveResponse
        //     ) else { throw .setPolicyFailed }
        //     SecTrustSetPolicies(trust, [policy, revocationPolicy] as CFArray)
        //
        // That forces a live OCSP lookup with a mandatory positive "good"
        // response — network-dependent by design.
        var error: CFError?
        guard SecTrustEvaluateWithError(trust, &error) else {
            throw .evaluateCertificateChainFailed(host: host, error: error)
        }

        // 6. Extract the server certificate chain from the trust management object.
        //    Needed so the chain includes the root for pin matching.
        //    (the server root certificate is usually not provided by the server)
        let serverCertificates: [SecCertificate] = SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? []

        guard !serverCertificates.isEmpty else {
            throw .copyCertificateChainFailed
        }

        // 7. Verify that at least one of the host's pins matches a
        //    certificate in the validated chain.
        guard pinsForHost.contains(where: { pin in
            // Does this pin match one of the chain's certificates?
            serverCertificates.contains { pin.matches($0) }
        }) else {
            throw .pinningFailed(host: host, serverCertificates: serverCertificates)
        }

        // The server certificate chain was successfully verified against a pinned certificate.
        return true
    }
}
