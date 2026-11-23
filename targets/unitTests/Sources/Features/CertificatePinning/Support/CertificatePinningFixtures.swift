//
//  CertificatePinningFixtures.swift
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

// MARK: - Certificates
//
// A throwaway CA ("AMI Unit Test CA", EC P-384) and one leaf per key type it can
// sign, each with its own SAN. Leaves carry the serverAuth extended key usage and a
// 800-day validity, which is what `SecTrustEvaluateWithError` requires for a
// standards-compliant server chain. Everything the tests evaluate is anchored to
// this CA — the system trust store is never consulted (see `TrustFactory`).
//
// Regenerating the fixtures (openssl):
//   openssl ecparam -name secp384r1 -genkey -noout -out ca.key
//   openssl req -new -x509 -key ca.key -out ca.pem -days 3650 \
//     -subj "/CN=AMI Unit Test CA" -extensions v3_ca -config ca.cnf   # CA:TRUE + keyCertSign
//   # per leaf: genrsa/ecparam → req -new → x509 -req -CA ca.pem -days 800 -extfile leaf.cnf
//   # leaf.cnf: basicConstraints=CA:FALSE, keyUsage=critical,digitalSignature,
//   #           extendedKeyUsage=serverAuth, subjectAltName=DNS:<san>
//
// The DER below is committed exactly as generated. If a test fails against a
// golden, either the code under test regressed, or the fixtures were re-generated
// on purpose (then review the diff).

enum TestCerts {
    /// DER of the test CA (EC P-384, CA:TRUE, valid until 2036).
    private static let testCA = "MIIBtzCCAT2gAwIBAgIUEOA2DRWw0rFMp5HE4F+bXDa+B3gwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA1NDVaFw0zNjExMTYwOTA1NDVaMBsxGTAXBgNVBAMMEEFNSSBVbml0IFRlc3QgQ0EwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAASg1bDZU3yZRZabKwGmxYSqOveJDvVe2gW6cp8dN7dUGkQ3psqdzMjAyBAr83NCif9/iJrKLaRRjH4HJTYu3kgQdFllSUXBAOKkrQX+djM18DL9/k55fqHUHTp3rR3OXb+jQjBAMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMB0GA1UdDgQWBBSMLzq4MjL5it6if37q+1pm7WcW0zAKBggqhkjOPQQDAgNoADBlAjEAukSRKYehRNsKG0+m8Vd6LugEk6SLtuIX0Gj/mF5UZEbDTolSUO3+oqHks2Y8AB9OAjAzH9GnWY+2FqMgA7OmcNPhB2oGDpDqkmrddjJVg3A+E6TDQWLNJi63fLnksWesAmU="

    /// Leaf signed by the test CA — RSA 2048, SAN `rsa.example`, serverAuth EKU, 800-day validity.
    private static let rsaLeaf = "MIICqjCCAjCgAwIBAgIUe6Wf0X2CqxtPpTiAlhYirhOjYWkwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA3MjJaFw0yOTAxMjcwOTA3MjJaMBYxFDASBgNVBAMMC3JzYS5leGFtcGxlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwMqnTSpMDq0LtWTQgKt/KG9x05kKsg3sh//I+gViyqpp0EEEL6UuBCR1BW6bnnQ3MWKwIQAUa1czR8OC1cKvCSJnlTBBsCnBHgalBxBjpZHp65N9bxyVrPtT7U03Lc72f96M+U13nYOdtgpFRegjdDgp9WXVwilkflTI4cq6f9qKnHpi/REbtXSnMwLE/MeYEOYfo+mP6Z3FQQTzTRXLiIKLOTbjZOE0hNFafD1tfI9uciAQpYyNQQUFbwL6lqCqhu943brQ+rUxvuZFYNqCQE1Umyo6cYb3c8MVNIu2VfcidpZn/xs8cey6isAudKkyzoM3TVmnVoWeGFdnwtpSdQIDAQABo4GLMIGIMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBYGA1UdEQQPMA2CC3JzYS5leGFtcGxlMB0GA1UdDgQWBBR/HMeNPH+OP5BLyFLh+QnZr7GmZDAfBgNVHSMEGDAWgBSMLzq4MjL5it6if37q+1pm7WcW0zAKBggqhkjOPQQDAgNoADBlAjALdlvYjpMTI3wL8qI8MzHQQX6aQEnljIs2tf6lhO4W+8sd9WRdTNOI6g7V0jt/mfgCMQC3kUP2juflPEvFLQ9JZIJnpPfhyX3xREOx86KujmvVcXcZXY5j619OR2eAhVilUeE="

    /// Leaf signed by the test CA — EC P-256, SAN `ec.example`, serverAuth EKU, 800-day validity.
    private static let ecP256Leaf = "MIIB3DCCAWOgAwIBAgIUe6Wf0X2CqxtPpTiAlhYirhOjYWowCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA3MjJaFw0yOTAxMjcwOTA3MjJaMBUxEzARBgNVBAMMCmVjLmV4YW1wbGUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARNqOwtKTijuhKQffgs2taANDYJF6C27voegJXLCOgXKcXQaZXeJDSLF3IiY75LHdEWk+ERdt0vM6LNsRNsEeWpo4GKMIGHMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBUGA1UdEQQOMAyCCmVjLmV4YW1wbGUwHQYDVR0OBBYEFD1eJVYF+NiThCviKjUlA4vXeg4YMB8GA1UdIwQYMBaAFIwvOrgyMvmK3qJ/fur7WmbtZxbTMAoGCCqGSM49BAMCA2cAMGQCMHkPoyASAMNe/egddz8J/MBn+4PmzPLDEen88RPu/UnOnzgjDdOtIx0aHadINIHLdwIwGxC9qRbFnoTYqQdwN89UmxESgM+38qyyUNU9UAmK2jo3hl73FBYtCtqFlqPCwKov"

    /// Leaf signed by the test CA — EC P-384, SAN `p384.example`, serverAuth EKU, 800-day validity.
    private static let ecP384Leaf = "MIIB/TCCAYSgAwIBAgIUe6Wf0X2CqxtPpTiAlhYirhOjYWswCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA3MjJaFw0yOTAxMjcwOTA3MjJaMBcxFTATBgNVBAMMDHAzODQuZXhhbXBsZTB2MBAGByqGSM49AgEGBSuBBAAiA2IABNsZGVKSPjtNAjMBvP9htYa/Dtr+EcBzCxYblGIARtKmrKF1Cc8bTjdkTEwnU+TgtDb5N4tNNLSnTOhx/Y1D57N6XTkn6puL5gFjjSPKnpa14gO9T+AKcnHz0t+XSp0BMaOBjDCBiTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDATAXBgNVHREEEDAOggxwMzg0LmV4YW1wbGUwHQYDVR0OBBYEFAJFX2C76kq75wevW1is2Y733StyMB8GA1UdIwQYMBaAFIwvOrgyMvmK3qJ/fur7WmbtZxbTMAoGCCqGSM49BAMCA2cAMGQCMBGXepErmV2Pso8NsMC8TGMWkM4E0xdN2Juye+tmws0r41LReKSot6WtCwR+kiD5fAIwHkUs7sT7tK561ITHvrIa+pNY+bt4tXlfTQRz0qXf5Z2vQhoA1HtVFaBLfG8aI77R"

    /// Leaf signed by the test CA — EC P-521, SAN `p521.example`, serverAuth EKU, 800-day validity.
    /// Its SPKI is the only fixture whose own DER lengths cross the 127-byte short/long form
    /// boundary (`30 81 9A …`), exercising the long-form branch of the `SPKI` DER walker.
    private static let ecP521Leaf = "MIICIzCCAaqgAwIBAgIUe6Wf0X2CqxtPpTiAlhYirhOjYWwwCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA3MjJaFw0yOTAxMjcwOTA3MjJaMBcxFTATBgNVBAMMDHA1MjEuZXhhbXBsZTCBmzAQBgcqhkjOPQIBBgUrgQQAIwOBhgAEADVBMh45WdjeSZR9VBGDNQr4+Ibjq98uuBewl/A7w+vkEjRCpeGByKpiZX40yEwBvEQ+6H0Cw8Hb4sUDxg6LcjsGAMvygwDuFL8ODNXzngpt62h20qG7+URGE5BFre99TIy1jaxwQCXPbvr7EuERvOmBbg0UgtnTTd1I9yCy33MT/woKo4GMMIGJMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBcGA1UdEQQQMA6CDHA1MjEuZXhhbXBsZTAdBgNVHQ4EFgQUTaI9k+qAbIHb9+P5Y0LjvV6NQ1swHwYDVR0jBBgwFoAUjC86uDIy+Yreon9+6vtaZu1nFtMwCgYIKoZIzj0EAwIDZwAwZAIwLFHFBm/iqi7rgXTgvaxBnKDEcNgYXkYKi3eaw7fFRNQPAaSokjZGjQIKYvpixBoYAjAd8sjaFWqcGY6ch8yGRaPp6lgkwv81f9zXIIM7LimcDAaLPUCaalKSFWUztwdNVcc="

    /// Standalone self-signed certificate (RSA 2048, SAN `localhost`), signed by
    /// no one in particular. It is the "garbage" certificate: it must never be
    /// accepted by a pinned rule, and it is the payload of the unpinned-host
    /// regression test.
    private static let selfSigned = "MIIDHTCCAgWgAwIBAgIUUv/yf3FLpBZINGkXM9WSvr6ffU0wDQYJKoZIhvcNAQELBQAwFDESMBAGA1UEAwwJbG9jYWxob3N0MB4XDTI2MTExOTA5MDcyMloXDTI5MDEyNzA5MDcyMlowFDESMBAGA1UEAwwJbG9jYWxob3N0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAko1mkfgZOvgY0oIoujymEikuiQxYokGQ8gwqQrJBJ2JuaVRENI6mgiSxzMdsJDHOUbxUdU9z6aMn0HZwwacjhmwG3cLs/ztV4CvUHPeD9cmtoNXQa37QsCTxooDrQr5HTAKOlhUF8cNaCTHFGXef66uc/j+0NOM63Hh8lf/FTEGGgzQeCSmg/Dl8keYHVNiQvzjBhQmV7Lxj3z1azSHBxwfSK40WWQTvSgcidRCb8qGCKy4lCxMA0psLiap+ZghyZuI5Bu5SOPOgZn1n7X5J6KpzF7YtrtXmQfnDCRpmvSjVwDCvS5b2jFNiLCN4Brslq0CZc8Z6F5ejxNfqdAeh9wIDAQABo2cwZTAJBgNVHRMEAjAAMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDATAUBgNVHREEDTALgglsb2NhbGhvc3QwHQYDVR0OBBYEFBcoz/Qr9osw20ZFbxPLQBAK93xmMA0GCSqGSIb3DQEBCwUAA4IBAQCLsga8Lpk07qBd8NGnkmaYxxjflsyiVe3ymXENLoe6pEF3Iv/iV7imWO9jc4RpW2dj39ahCS2ewRi4DYbCnaRKirgAIOCBhupfRozOBxk7gdGoeWaelfbGrXEzo8kIR/3H2kmJXWR4r0Bvl3LWcxbr1mV4c4okLfu7FSiRlrCjuxftOd16zymCl1Vla0z9b1orljJgKjjV1EgVSB3XplkkpGnYkgJ7/Bqe3zOwnlOKaWIJjZsTy3OdsDRkqX5zu3fOyy0SDAYzfAqNdgnjucWnmeMs7Z2UcLyehvU+GGtuX04PAOVB+18DLKzG8BkLEKY9Dl6ElxIkaib5uUblRHct"

    private static func certificate(derBase64: String) -> SecCertificate {
        let data = Data(base64Encoded: derBase64)!
        return SecCertificateCreateWithData(nil, data as CFData)!
    }

    static let ca: SecCertificate = certificate(derBase64: testCA)
    static let rsa: SecCertificate = certificate(derBase64: rsaLeaf)
    static let ecP256: SecCertificate = certificate(derBase64: ecP256Leaf)
    static let ecP384: SecCertificate = certificate(derBase64: ecP384Leaf)
    static let ecP521: SecCertificate = certificate(derBase64: ecP521Leaf)
    static let selfSignedCert: SecCertificate = certificate(derBase64: selfSigned)
}

// MARK: - Golden values
//
// Independent oracles for the extraction tests, produced by the same openssl
// pipeline used to generate production pins:
//   FULL_DER    = openssl x509 -in leaf.pem -outform DER
//   SPKI_DER    = openssl x509 -in leaf.pem -noout -pubkey | openssl pkey -pubin -outform DER
//   SPKI_SHA256 = SPKI_DER | openssl dgst -sha256 -binary | openssl base64 -A
//   PKCS1       = openssl rsa -pubin -inform DER -in SPKI_DER -RSAPublicKey_out -outform DER
//   X9.63 point = BIT STRING content of SPKI_DER, minus the leading 0x00 byte

enum Goldens {
    // Test CA
    static let caSpkiSha256 = "w08zVcSCtIVSkhE/JvJUN0PLtJiUygqai/s2B7zh3Lw="

    // rsa.example — RSA 2048
    static let rsaSpkiDer = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwMqnTSpMDq0LtWTQgKt/KG9x05kKsg3sh//I+gViyqpp0EEEL6UuBCR1BW6bnnQ3MWKwIQAUa1czR8OC1cKvCSJnlTBBsCnBHgalBxBjpZHp65N9bxyVrPtT7U03Lc72f96M+U13nYOdtgpFRegjdDgp9WXVwilkflTI4cq6f9qKnHpi/REbtXSnMwLE/MeYEOYfo+mP6Z3FQQTzTRXLiIKLOTbjZOE0hNFafD1tfI9uciAQpYyNQQUFbwL6lqCqhu943brQ+rUxvuZFYNqCQE1Umyo6cYb3c8MVNIu2VfcidpZn/xs8cey6isAudKkyzoM3TVmnVoWeGFdnwtpSdQIDAQAB"
    static let rsaSpkiSha256 = "QCZJ3uBhAkwV65KyCNYsplX1FFYUFRW9tjkMmVSpuR4="
    static let rsaPkcs1 = "MIIBCgKCAQEAwMqnTSpMDq0LtWTQgKt/KG9x05kKsg3sh//I+gViyqpp0EEEL6UuBCR1BW6bnnQ3MWKwIQAUa1czR8OC1cKvCSJnlTBBsCnBHgalBxBjpZHp65N9bxyVrPtT7U03Lc72f96M+U13nYOdtgpFRegjdDgp9WXVwilkflTI4cq6f9qKnHpi/REbtXSnMwLE/MeYEOYfo+mP6Z3FQQTzTRXLiIKLOTbjZOE0hNFafD1tfI9uciAQpYyNQQUFbwL6lqCqhu943brQ+rUxvuZFYNqCQE1Umyo6cYb3c8MVNIu2VfcidpZn/xs8cey6isAudKkyzoM3TVmnVoWeGFdnwtpSdQIDAQAB"

    // ec.example — EC P-256
    static let ecP256FullDer = "MIIB3DCCAWOgAwIBAgIUe6Wf0X2CqxtPpTiAlhYirhOjYWowCgYIKoZIzj0EAwIwGzEZMBcGA1UEAwwQQU1JIFVuaXQgVGVzdCBDQTAeFw0yNjExMTkwOTA3MjJaFw0yOTAxMjcwOTA3MjJaMBUxEzARBgNVBAMMCmVjLmV4YW1wbGUwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARNqOwtKTijuhKQffgs2taANDYJF6C27voegJXLCOgXKcXQaZXeJDSLF3IiY75LHdEWk+ERdt0vM6LNsRNsEeWpo4GKMIGHMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMBMBUGA1UdEQQOMAyCCmVjLmV4YW1wbGUwHQYDVR0OBBYEFD1eJVYF+NiThCviKjUlA4vXeg4YMB8GA1UdIwQYMBaAFIwvOrgyMvmK3qJ/fur7WmbtZxbTMAoGCCqGSM49BAMCA2cAMGQCMHkPoyASAMNe/egddz8J/MBn+4PmzPLDEen88RPu/UnOnzgjDdOtIx0aHadINIHLdwIwGxC9qRbFnoTYqQdwN89UmxESgM+38qyyUNU9UAmK2jo3hl73FBYtCtqFlqPCwKov"
    static let ecP256SpkiDer = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAETajsLSk4o7oSkH34LNrWgDQ2CRegtu76HoCVywjoFynF0GmV3iQ0ixdyImO+Sx3RFpPhEXbdLzOizbETbBHlqQ=="
    static let ecP256SpkiSha256 = "5HBPHwcQ+nilEL429FbCPkhuiaupEIhLD9HJJo0wZT0="
    static let ecP256FullSha256 = "NAe/W/7otIHYLUaH8qkTzHb/1ce8ZXIWlsrzcYI01qI="
    static let ecP256X963 = "BE2o7C0pOKO6EpB9+Cza1oA0NgkXoLbu+h6AlcsI6BcpxdBpld4kNIsXciJjvksd0RaT4RF23S8zos2xE2wR5ak="

    // p384.example — EC P-384
    static let ecP384SpkiDer = "MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAE2xkZUpI+O00CMwG8/2G1hr8O2v4RwHMLFhuUYgBG0qasoXUJzxtON2RMTCdT5OC0Nvk3i000tKdM6HH9jUPns3pdOSfqm4vmAWONI8qelrXiA71P4ApycfPS35dKnQEx"
    static let ecP384SpkiSha256 = "p0qCZl3vNhSIJ0q8qOP94SGfTRwNlFTKAyCK0jawfAI="
    static let ecP384X963 = "BNsZGVKSPjtNAjMBvP9htYa/Dtr+EcBzCxYblGIARtKmrKF1Cc8bTjdkTEwnU+TgtDb5N4tNNLSnTOhx/Y1D57N6XTkn6puL5gFjjSPKnpa14gO9T+AKcnHz0t+XSp0BMQ=="

    // p521.example — EC P-521 (SPKI top-level length is long-form: 30 81 9A)
    static let ecP521SpkiDer = "MIGbMBAGByqGSM49AgEGBSuBBAAjA4GGAAQANUEyHjlZ2N5JlH1UEYM1Cvj4huOr3y64F7CX8DvD6+QSNEKl4YHIqmJlfjTITAG8RD7ofQLDwdvixQPGDotyOwYAy/KDAO4Uvw4M1fOeCm3raHbSobv5REYTkEWt731MjLWNrHBAJc9u+vsS4RG86YFuDRSC2dNN3Uj3ILLfcxP/Cgo="
    static let ecP521SpkiSha256 = "C+T0go4YXmV8jw+zsVciz7hNTyhrp8vlKRLFiHSfOHI="
    static let ecP521X963 = "BAA1QTIeOVnY3kmUfVQRgzUK+PiG46vfLrgXsJfwO8Pr5BI0QqXhgciqYmV+NMhMAbxEPuh9AsPB2+LFA8YOi3I7BgDL8oMA7hS/DgzV854KbetodtKhu/lERhOQRa3vfUyMtY2scEAlz276+xLhEbzpgW4NFILZ003dSPcgst9zE/8KCg=="

    // Self-signed garbage certificate
    static let selfSignedSpkiSha256 = "6CC14v7zj1R3Aj36JvQqjgts95xkudmpvgS5IOH5Azo="
}

// swiftformat:enable all
// swiftlint:enable all
