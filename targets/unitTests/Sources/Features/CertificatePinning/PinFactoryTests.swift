//
//  PinFactoryTests.swift
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

// MARK: - PinFactory
//
// The factory is the single entry point that turns a base64 literal into a
// `TrustChainNode`. These tests pin the wiring (right case → right concrete
// node), the failure mode (bad input → `nil`, never a trap) and the literals
// shipped in `DependencyContainer`.

@Suite("PinFactory")
struct PinFactoryTests {

    @Test func producesTheExpectedConcreteNodes() throws {
        #expect(try #require(PinFactory.certificate.makePin(base64Representation: Goldens.ecP256FullDer))
               is Certificate)
        #expect(try #require(PinFactory.spki.makePin(algorithm: .sha256,
                                                     base64Representation: Goldens.ecP256SpkiSha256))
               is HashedPin<SPKI, SHA256>)
        // Every public-key pin is built from the base64 of the SPKI DER:
        // `RSA.Signing.PublicKey` validates it (deriving PKCS#1 on demand) and
        // CryptoKit's `derRepresentation` initializer only accepts SPKI for EC.
        // The resulting `PublicKey` node stores the RAW key material (X9.63 point
        // or PKCS#1), which is exactly what `PublicKey.extracted(from:)` returns.
        #expect(try #require(PinFactory.publicKey(.rsa).makePin(base64Representation: Goldens.rsaSpkiDer))
               is PublicKey)
        #expect(try #require(PinFactory.publicKey(.p256).makePin(base64Representation: Goldens.ecP256SpkiDer))
               is PublicKey)
        #expect(try #require(PinFactory.publicKey(.p384).makePin(base64Representation: Goldens.ecP384SpkiDer))
               is PublicKey)
        #expect(try #require(PinFactory.publicKey(.p521).makePin(base64Representation: Goldens.ecP521SpkiDer))
               is PublicKey)
    }

    /// Self-verifying round trip: the factory takes the SPKI DER, stores the raw
    /// key material — the very bytes `SecKey` extracts from the certificate —
    /// so the resulting pin must match it.
    @Test func publicKeyFactoryRoundTripsThroughExtraction() throws {
        let pin = try #require(PinFactory.publicKey(.p256).makePin(base64Representation: Goldens.ecP256SpkiDer))
        let raw = try #require(PublicKey.extracted(from: TestCerts.ecP256)).data
        #expect(pin.data == raw)
        #expect(pin.matches(TestCerts.ecP256))
        #expect(!pin.matches(TestCerts.ecP384))
    }

    @Test func malformedRepresentationsYieldNil() {
        #expect(PinFactory.certificate.makePin(base64Representation: "") == nil)
        #expect(PinFactory.certificate.makePin(base64Representation: "not base64 !!!") == nil)
        #expect(PinFactory.publicKey(.p256).makePin(base64Representation: "not-a-key") == nil)
        // Wrong key type: an EC SPKI is not a valid RSA key (and vice versa).
        #expect(PinFactory.publicKey(.rsa).makePin(base64Representation: Goldens.ecP256SpkiDer) == nil)
        #expect(PinFactory.publicKey(.p256).makePin(base64Representation: Goldens.rsaSpkiDer) == nil)
    }

    /// Well-formed but foreign digest: decodes into a valid pin, yet matches
    /// nothing it was not computed from.
    @Test func foreignDigestDecodesButMatchesNothing() throws {
        let pin = try #require(PinFactory.spki.makePin(algorithm: .sha256,
                                                       base64Representation: Goldens.rsaSpkiSha256))
        #expect(!pin.matches(TestCerts.ecP256))
        #expect(pin.matches(TestCerts.rsa))
    }

    // MARK: - Production pin decode regression

    /// The base64 literals shipped in `DependencyContainer`, decoded through the exact
    /// factory path the app uses. A typo or truncation must fail in CI instead of
    /// silently degrading pinning at runtime.
    @Test func productionPinsStillDecode() {
        let cloudflareIntermediateSpki = PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Self.literals.cloudflareIntermediateSpki)
        #expect(cloudflareIntermediateSpki != nil, "cloudflareIntermediateSpki failed to decode")
        let amiPreprodCertificateFull = PinFactory.certificate.makePin(base64Representation: Self.literals.amiPreprodCertificateFull)
        #expect(amiPreprodCertificateFull != nil, "amiPreprodCertificateFull failed to decode")
        let amiPreprodCertificateSha256 = PinFactory.certificate.makePin(algorithm: .sha256, base64Representation: Self.literals.amiPreprodCertificateSha256)
        #expect(amiPreprodCertificateSha256 != nil, "amiPreprodCertificateSha256 failed to decode")
        let amiPreprodPublicKeyRsaFull = PinFactory.publicKey(.rsa).makePin(base64Representation: Self.literals.amiPreprodPublicKeyRsaFull)
        #expect(amiPreprodPublicKeyRsaFull != nil, "amiPreprodPublicKeyRsaFull failed to decode")
        let amiPreprodPublicKeyRsaSha256 = PinFactory.publicKey(.rsa).makePin(algorithm: .sha256, base64Representation: Self.literals.amiPreprodPublicKeyRsaSha256)
        #expect(amiPreprodPublicKeyRsaSha256 != nil, "amiPreprodPublicKeyRsaSha256 failed to decode")
        let amiPreprodSpkiFull = PinFactory.spki.makePin(base64Representation: Self.literals.amiPreprodSpkiFull)
        #expect(amiPreprodSpkiFull != nil, "amiPreprodSpkiFull failed to decode")
        let amiPreprodSpkiSha256 = PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Self.literals.amiPreprodSpkiSha256)
        #expect(amiPreprodSpkiSha256 != nil, "amiPreprodSpkiSha256 failed to decode")
        let amiPreprodSpkiSha256SelfSigned = PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Self.literals.amiPreprodSpkiSha256SelfSigned)
        #expect(amiPreprodSpkiSha256SelfSigned != nil, "amiPreprodSpkiSha256SelfSigned failed to decode")
    }

    private enum literals {
        static let cloudflareIntermediateSpki = "kIdp6NNEd8wsugYyyIYFsi1ylMCED3hZbSR8ZFsa/A4="
        static let amiPreprodCertificateFull = "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"
        static let amiPreprodCertificateSha256 = "NIXD3+mMXVQoZTR5u5BidYDuiSiQpi2g2avOOiAC6OQ="
        static let amiPreprodPublicKeyRsaFull = "MIICCgKCAgEAtYLYqJhQGMspeeK32effq0+8qvLe/CX19wgxazykiWNCTVuf/Un47xruGkTl2itXoGmc6M3edVGTolY3eNv6HrPo27rMuh5oI3WTfI7twbkiJu1cEeaVCfR/GjqeNDJF3kaLuqmWj9nGrfNgzffNpT63Tw2YKhM/4Vpk8YUxaFWpDaGXqMO7aIRjb7BMs6lcZ35MSdWBJbr44fyOHd+dB0ObmfRKJP1UIPk6Z3WtOD46lLhZ6JfL08/2bOTUwLiQV9IyZwph855AErg9wkXRwak+/5fQF/43eIqJsse8RoTn00G9sMiO8feSNs5bGMgx45S4oAcaBYLh1PnLpHf5pBr9ZiLwE8uTHXo7gHvClXgJefQqevUfuwhfZ//1NfWUitBZexIlhH/jOaM4QF4F0KHUiQl96ce1ug1NP9DbKhcYNibxgS1HPEIK/O5G7GSclx0HzzwcM68VqcKwgXY7tWpaKtKwxEAQ/4bP3KMbAgyW35++8p+oHLE+21q5M+V6jYQFXMTydKZiusJn1dsy8fo3XIE5R3tqeplgaxW8Hg8/C76JOLVp7CueYARxXuydEPmGfIPY/TjjNp6HWa5UC529yonDn0a9WgISJz4pt7KsdSMk1wBLvP/Z/ksZcLnc8/7g16WbQvEnleUYBrWUqenSceE60pvNoGmWijtiTRcCAwEAAQ=="
        static let amiPreprodPublicKeyRsaSha256 = "HE9yjEybp5c48uhgITqAV/OAUicPipiYtt7Wju1a73Y="
        static let amiPreprodSpkiFull = "MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtYLYqJhQGMspeeK32effq0+8qvLe/CX19wgxazykiWNCTVuf/Un47xruGkTl2itXoGmc6M3edVGTolY3eNv6HrPo27rMuh5oI3WTfI7twbkiJu1cEeaVCfR/GjqeNDJF3kaLuqmWj9nGrfNgzffNpT63Tw2YKhM/4Vpk8YUxaFWpDaGXqMO7aIRjb7BMs6lcZ35MSdWBJbr44fyOHd+dB0ObmfRKJP1UIPk6Z3WtOD46lLhZ6JfL08/2bOTUwLiQV9IyZwph855AErg9wkXRwak+/5fQF/43eIqJsse8RoTn00G9sMiO8feSNs5bGMgx45S4oAcaBYLh1PnLpHf5pBr9ZiLwE8uTHXo7gHvClXgJefQqevUfuwhfZ//1NfWUitBZexIlhH/jOaM4QF4F0KHUiQl96ce1ug1NP9DbKhcYNibxgS1HPEIK/O5G7GSclx0HzzwcM68VqcKwgXY7tWpaKtKwxEAQ/4bP3KMbAgyW35++8p+oHLE+21q5M+V6jYQFXMTydKZiusJn1dsy8fo3XIE5R3tqeplgaxW8Hg8/C76JOLVp7CueYARxXuydEPmGfIPY/TjjNp6HWa5UC529yonDn0a9WgISJz4pt7KsdSMk1wBLvP/Z/ksZcLnc8/7g16WbQvEnleUYBrWUqenSceE60pvNoGmWijtiTRcCAwEAAQ=="
        static let amiPreprodSpkiSha256 = "kGxKeLInUl4Q9pvlALRV0c2jCDMtv5OZYa/lU99H6bo="
        static let amiPreprodSpkiSha256SelfSigned = "8z1diKiyh+CoJrA2ogM4Sh4IjoFuZmCa7TImhSe0lzk="
    }

}

// swiftformat:enable all
// swiftlint:enable all
