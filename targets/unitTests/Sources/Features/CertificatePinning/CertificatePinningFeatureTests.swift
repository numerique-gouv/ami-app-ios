//
//  CertificatePinningFeatureTests.swift
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

// MARK: - Decision table
//
// `CertificatePinningFeature.evaluate(challenge:for:)` is a pure function
// `(challenge, host) → (disposition, credential)`. Every branch is pinned here:
//
// | Scenario                                        | Expected disposition          |
// |-------------------------------------------------|-------------------------------|
// | Host has no matching pin rule                   | .performDefaultHandling       |
// | Pinned, chain valid, a pin matches              | .useCredential (+ the trust)  |
// | Pinned, chain invalid (even if a pin would fit) | .cancelAuthenticationChallenge |
// | Pinned, chain valid, no pin matches             | .cancelAuthenticationChallenge |
// | Challenge is not a server-trust challenge       | .performDefaultHandling       |
// | Protection space carries no SecTrust            | .performDefaultHandling       |

@Suite("CertificatePinningFeature")
struct CertificatePinningFeatureTests {

    /// Rule matching only `ec.example`, pinned with the SPKI digest of the P-256 leaf.
    private static let ecSpkiSha256Rule = PinRule(pattern: "^ec\\.example$", pins: [
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.ecP256SpkiSha256),
    ])

    // MARK: Regression — the point-2 bypass

    /// An UNPINNED host with an untrusted self-signed certificate must fall back
    /// to `.performDefaultHandling`, letting the system run its normal validation.
    ///
    /// Regression: the evaluator used to silently return for unpinned hosts and
    /// the feature answered `.useCredential` with the unevaluated trust — which
    /// accepted ANY certificate, including self-signed ones (total TLS bypass).
    /// This test fails if that path ever answers `.useCredential` again.
    @Test func unpinnedHostFallsBackToSystemDefaultHandling() async {
        let feature = CertificatePinningFeature(pinRules: [Self.ecSpkiSha256Rule])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.challenge(host: "localhost", trust: TrustFactory.untrusted([TestCerts.selfSignedCert])),
            for: "localhost")

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    // MARK: Happy path

    @Test func pinnedHostWithValidChainAndMatchingPinIsAccepted() async {
        let feature = CertificatePinningFeature(pinRules: [Self.ecSpkiSha256Rule])
        let trust = TrustFactory.trust([TestCerts.ecP256, TestCerts.ca])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.challenge(host: "ec.example", trust: trust),
            for: "ec.example")

        #expect(disposition == .useCredential)
        #expect(credential != nil)
        // The SDK exposes no `trust` accessor on `URLCredential` (any platform).
        // Trust-credential equality is trust-instance-sensitive (probed), so the
        // credential must wrap the very SecTrust that was evaluated.
        #expect(credential == URLCredential(trust: trust))
    }

    // MARK: Fail-closed paths

    /// Validate-first ordering: the pin matches the leaf, but the chain is not
    /// anchored to a trusted root. Pinning must never compensate for a broken
    /// chain — the request is cancelled, not accepted.
    @Test func invalidChainCancelsEvenIfAPinWouldMatch() async {
        let feature = CertificatePinningFeature(pinRules: [Self.ecSpkiSha256Rule])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.challenge(host: "ec.example",
                                  trust: TrustFactory.untrusted([TestCerts.ecP256, TestCerts.ca])),
            for: "ec.example")

        #expect(disposition == .cancelAuthenticationChallenge)
        #expect(credential == nil)
    }

    /// The chain validates, but none of the pins matches any certificate in it.
    @Test func validChainWithWrongPinCancels() async {
        let wrongPinRule = PinRule(pattern: "^ec\\.example$", pins: [
            PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.rsaSpkiSha256),
        ])
        let feature = CertificatePinningFeature(pinRules: [wrongPinRule])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.challenge(host: "ec.example", trust: TrustFactory.trust([TestCerts.ecP256, TestCerts.ca])),
            for: "ec.example")

        #expect(disposition == .cancelAuthenticationChallenge)
        #expect(credential == nil)
    }

    // MARK: Out-of-scope challenges

    @Test func nonServerTrustChallengeIsLeftToTheSystem() async {
        let feature = CertificatePinningFeature(pinRules: [Self.ecSpkiSha256Rule])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.nonServerTrustChallenge(host: "ec.example"),
            for: "ec.example")

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }

    @Test func missingServerTrustIsLeftToTheSystem() async {
        let feature = CertificatePinningFeature(pinRules: [Self.ecSpkiSha256Rule])
        let (disposition, credential) = await feature.evaluate(
            challenge: ChallengeFactory.challenge(host: "ec.example", trust: nil),
            for: "ec.example")

        #expect(disposition == .performDefaultHandling)
        #expect(credential == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
