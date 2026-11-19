//
//  HashedPinTests.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 19/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

import CryptoKit
import Foundation
import Security
import Testing

@testable import AMI_Staging

// MARK: - HashedPin
//
// A `HashedPin<Node, Func>` stores ONE digest of the node's bytes and matches a
// certificate by hashing the node extracted from it. These tests pin the
// digest contract (length, base64 strictness) and the match semantics.

@Suite("HashedPin")
struct HashedPinTests {

    @Test func sha256SpkiPinMatchesOpenSSLDigest() throws {
        let pin = try #require(HashedPin<SPKI, SHA256>(base64Encoded: Goldens.ecP256SpkiSha256))
        #expect(pin.matches(TestCerts.ecP256))
        #expect(!pin.matches(TestCerts.ecP384))
        #expect(!pin.matches(TestCerts.rsa))
        #expect(!pin.matches(TestCerts.selfSignedCert))
    }

    @Test func sha256CertificatePinMatchesOpenSSLDigest() throws {
        let pin = try #require(HashedPin<Certificate, SHA256>(base64Encoded: Goldens.ecP256FullSha256))
        #expect(pin.matches(TestCerts.ecP256))
        #expect(!pin.matches(TestCerts.ecP384))
    }

    /// Self-consistency for the non-SHA256 algorithms: the digest is computed
    /// here by CryptoKit over the golden SPKI, so only the node→digest→match
    /// wiring of the feature is under test.
    @Test func sha384AndSha512SpkiPinsMatchTheirCertificate() throws {
        let spki = Data(base64Encoded: Goldens.ecP256SpkiDer)!
        let sha384 = Data(SHA384.hash(data: spki)).base64EncodedString()
        let sha512 = Data(SHA512.hash(data: spki)).base64EncodedString()

        let pin384 = try #require(HashedPin<SPKI, SHA384>(base64Encoded: sha384))
        #expect(pin384.matches(TestCerts.ecP256))
        #expect(!pin384.matches(TestCerts.ecP384))

        let pin512 = try #require(HashedPin<SPKI, SHA512>(base64Encoded: sha512))
        #expect(pin512.matches(TestCerts.ecP256))
        #expect(!pin512.matches(TestCerts.ecP384))
    }

    // MARK: base64 / digest-length strictness

    /// The decoded digest must be exactly `Func.Digest.byteCount` bytes.
    @Test func wrongDigestLengthIsRejected() {
        // 40 base64 chars → 30 bytes (SHA256 wants 32).
        #expect(HashedPin<SPKI, SHA256>(base64Encoded: String(repeating: "A", count: 40)) == nil)
        // 44 base64 chars → 33 bytes.
        #expect(HashedPin<SPKI, SHA256>(base64Encoded: String(repeating: "A", count: 44)) == nil)
    }

    /// `Data(base64Encoded:)` is strict: no newlines, no invalid characters.
    @Test func malformedBase64IsRejected() {
        #expect(HashedPin<Certificate, SHA256>(base64Encoded: "") == nil)
        #expect(HashedPin<Certificate, SHA256>(base64Encoded: "!!!") == nil)
        #expect(Certificate(base64Encoded: "AAAA\n") == nil)
    }

    /// A well-formed digest of the WRONG key must decode fine and match nothing.
    @Test func foreignDigestDecodesButMatchesNothing() throws {
        let pin = try #require(HashedPin<SPKI, SHA256>(base64Encoded: Goldens.rsaSpkiSha256))
        #expect(!pin.matches(TestCerts.ecP256))
        #expect(pin.matches(TestCerts.rsa))
    }
}

// swiftformat:enable all
// swiftlint:enable all
