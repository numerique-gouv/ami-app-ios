//
//  TrustChainNodeExtractionTests.swift
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

// MARK: - Extraction vs. openssl ground truth
//
// `TrustChainNode` correctness is data correctness: a DER walker bug is a
// one-byte slice shift, and a wrong slice silently breaks pin matching. These
// tests compare each node's `data` against the golden values produced by the
// same openssl pipeline used for production pins (see `Goldens`).

@Suite("TrustChainNode extraction")
struct TrustChainNodeExtractionTests {

    // MARK: Certificate

    @Test func certificateExtractsExactDER() throws {
        let extracted = try #require(Certificate.extracted(from: TestCerts.ecP256))
        #expect(extracted.data == Data(base64Encoded: Goldens.ecP256FullDer)!)
    }

    @Test func certificateInitRejectsNonCertificateData() {
        #expect(Certificate(base64Encoded: "AAAA") == nil)
    }

    // MARK: SPKI

    /// The sliced SPKI must be byte-identical to
    /// `openssl x509 -noout -pubkey | openssl pkey -pubin -outform DER`
    /// for every key type the feature supports.
    @Test func spkiMatchesOpenSSLPipelineForAllKeyTypes() throws {
        #expect(SPKI.extracted(from: TestCerts.rsa)?.data
               == Data(base64Encoded: Goldens.rsaSpkiDer)!)
        #expect(SPKI.extracted(from: TestCerts.ecP256)?.data
               == Data(base64Encoded: Goldens.ecP256SpkiDer)!)
        #expect(SPKI.extracted(from: TestCerts.ecP384)?.data
               == Data(base64Encoded: Goldens.ecP384SpkiDer)!)
        // P-521 SPKI's own DER lengths are long-form (30 81 9A …): this is the
        // fixture that exercises that branch of the walker.
        #expect(SPKI.extracted(from: TestCerts.ecP521)?.data
               == Data(base64Encoded: Goldens.ecP521SpkiDer)!)
    }

    @Test func spkiInitRoundTripsWithExtraction() throws {
        let fromBase64 = try #require(SPKI(base64Encoded: Goldens.ecP256SpkiDer))
        let extracted = try #require(SPKI.extracted(from: TestCerts.ecP256))
        #expect(fromBase64 == extracted)
    }

    @Test func spkiInitRejectsMalformedDER() {
        #expect(SPKI(base64Encoded: "AAAA") == nil)               // not a SEQUENCE
        // Truncated SPKI: the declared length no longer covers the payload.
        let truncated = String(Goldens.ecP256SpkiDer.prefix(Goldens.ecP256SpkiDer.count - 8))
        #expect(SPKI(base64Encoded: truncated) == nil)
    }

    // MARK: PublicKey

    /// `SecKeyCopyExternalRepresentation` returns PKCS#1 for RSA and the X9.63
    /// uncompressed point (04 ‖ X ‖ Y) for EC — exactly what the goldens hold.
    @Test func publicKeyExtractionIsPerAlgorithm() throws {
        #expect(PublicKey.extracted(from: TestCerts.rsa)?.data
               == Data(base64Encoded: Goldens.rsaPkcs1)!)
        #expect(PublicKey.extracted(from: TestCerts.ecP256)?.data
               == Data(base64Encoded: Goldens.ecP256X963)!)
        #expect(PublicKey.extracted(from: TestCerts.ecP384)?.data
               == Data(base64Encoded: Goldens.ecP384X963)!)
        #expect(PublicKey.extracted(from: TestCerts.ecP521)?.data
               == Data(base64Encoded: Goldens.ecP521X963)!)
    }

    // MARK: matches()

    @Test func matchesIsPositiveOnlyForItsOwnCertificate() throws {
        let pin = try #require(SPKI.extracted(from: TestCerts.ecP256))
        #expect(pin.matches(TestCerts.ecP256))
        #expect(!pin.matches(TestCerts.rsa))
        #expect(!pin.matches(TestCerts.ecP384))
        #expect(!pin.matches(TestCerts.ecP521))
        #expect(!pin.matches(TestCerts.selfSignedCert))
    }

    // MARK: RSA.Signing.PublicKey

    @Test func rsaSigningPublicKeyStoresSPKIAndDerivesPKCS1() throws {
        let key = try RSA.Signing.PublicKey(derRepresentation: Data(base64Encoded: Goldens.rsaSpkiDer)!)
        #expect(key.derRepresentation == Data(base64Encoded: Goldens.rsaSpkiDer)!)
        #expect(key.pkcs1Representation == Data(base64Encoded: Goldens.rsaPkcs1)!)
    }

    @Test func rsaSigningPublicKeyRejectsNonRSAKeys() {
        let ecDer = Data(base64Encoded: Goldens.ecP256SpkiDer)!
        #expect((try? RSA.Signing.PublicKey(derRepresentation: ecDer)) == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
