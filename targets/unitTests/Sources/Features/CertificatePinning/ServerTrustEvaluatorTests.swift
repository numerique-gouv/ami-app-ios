//
//  ServerTrustEvaluatorTests.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 19/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Security
import Testing

@testable import AMI_Staging

// MARK: - Evaluator matrix
//
// `ServerTrustEvaluator.evaluate` returns:
//   `true`   → host pinned, chain verified, at least one pin matched
//   `false`  → host has no pin rules (the system default applies)
//   throw    → host pinned, but validation or pinning failed
//
// Chains are built against the hermetic test CA (see `TrustFactory`), so the
// system trust store never influences these results.

@Suite("ServerTrustEvaluator")
struct ServerTrustEvaluatorTests {

    private static let ecSpkiSha256Rule = PinRule(pattern: "^ec\\.example$", pins: [
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.ecP256SpkiSha256),
    ])

    /// Runs the evaluator and boxes the typed result (typed throws: `error` in
    /// the catch clause is already a `CertificatePinningError`).
    private func run(_ rules: [PinRule], trust: SecTrust, host: String) async -> Result<Bool, CertificatePinningError> {
        let evaluator = ServerTrustEvaluator(pinRules: rules)
        do { return .success(try await evaluator.evaluate(trust, forHost: host)) }
        catch { return .failure(error) }
    }

    private func expectSuccess(_ result: Result<Bool, CertificatePinningError>, _ value: Bool) {
        switch result {
        case .success(let ok):
            #expect(ok == value)
        case .failure(let error):
            Issue.record("Expected success(\(value)), the evaluator threw \(error)")
        }
    }

    private func expectPinningFailed(_ result: Result<Bool, CertificatePinningError>) {
        switch result {
        case .failure(.pinningFailed):
            break
        default:
            Issue.record("Expected .pinningFailed, got \(result)")
        }
    }

    private func expectChainValidationFailed(_ result: Result<Bool, CertificatePinningError>) {
        switch result {
        case .failure(.evaluateCertificateChainFailed):
            break
        default:
            Issue.record("Expected .evaluateCertificateChainFailed, got \(result)")
        }
    }

    // MARK: Unpinned host

    /// No rule matches the host → `false`, WITHOUT evaluating the trust: even a
    /// garbage self-signed certificate must not produce a throw (and never a
    /// `true`). The feature maps this to `.performDefaultHandling`.
    @Test func hostWithNoPinsReturnsFalseWithoutEvaluating() async {
        let result = await run([Self.ecSpkiSha256Rule],
                               trust: TrustFactory.untrusted([TestCerts.selfSignedCert]),
                               host: "unpinned.example")
        expectSuccess(result, false)
    }

    // MARK: Pinned host, valid chain

    @Test func pinnedHostWithValidChainAndMatchingPinReturnsTrue() async {
        let result = await run([Self.ecSpkiSha256Rule],
                               trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca]),
                               host: "ec.example")
        expectSuccess(result, true)
    }

    /// The match loop walks the WHOLE chain, not only the leaf: a pin derived
    /// from the intermediate (the test CA here) must also accept the chain.
    /// This is exactly how the production cloudflare rule is pinned (WE1).
    @Test func pinMatchingTheIntermediateCertificateSuffices() async {
        let caSpkiRule = PinRule(pattern: "^ec\\.example$", pins: [
            PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.caSpkiSha256),
        ])
        let result = await run([caSpkiRule],
                               trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca]),
                               host: "ec.example")
        expectSuccess(result, true)
    }

    /// Host selection is case-insensitive (DNS names are).
    @Test func hostMatchingIsCaseInsensitive() async {
        let result = await run([Self.ecSpkiSha256Rule],
                               trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca]),
                               host: "EC.EXAMPLE")
        expectSuccess(result, true)
    }

    // MARK: Pinned host, failures

    /// Chain fully valid, but no pin matches → the failure must be the PIN check
    /// (step 7), not an earlier validation step.
    @Test func validChainWithWrongPinThrowsPinningFailed() async {
        let wrongPinRule = PinRule(pattern: "^ec\\.example$", pins: [
            PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.rsaSpkiSha256),
        ])
        let result = await run([wrongPinRule],
                               trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca]),
                               host: "ec.example")
        expectPinningFailed(result)
    }

    /// The pin matches the leaf, but the chain does not validate (no trusted
    /// anchor) → validation (step 5) fails BEFORE any pin is consulted.
    @Test func invalidChainThrowsEvaluateCertificateChainFailed() async {
        let result = await run([Self.ecSpkiSha256Rule],
                               trust: TrustFactory.untrusted([TestCerts.ecP256, TestCerts.ca]),
                               host: "ec.example")
        expectChainValidationFailed(result)
    }

    /// Pinning must not weaken hostname verification: the rule matches the host
    /// and the chain is valid, but the leaf's SAN does not include the host —
    /// the SSL policy (step 5) must reject it.
    @Test func hostnameMismatchThrowsEvaluateCertificateChainFailed() async {
        let bothHostsRule = PinRule(pattern: "^(ec|other)\\.example$", pins: [
            PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.ecP256SpkiSha256),
        ])
        let result = await run([bothHostsRule],
                               trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca]),
                               host: "other.example")
        expectChainValidationFailed(result)
    }
}

// swiftformat:enable all
// swiftlint:enable all
