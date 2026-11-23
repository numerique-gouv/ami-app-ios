//
//  SPKI.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 17/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Trust chain node identified by the Subject Public Key Info (SPKI)
/// embedded in a certificate.
///
/// The SPKI is the standard unit for hashed key pinning (the historical
/// HPKP `pin-sha256` format): unlike a whole-certificate pin it survives
/// re-issuance as long as the public key is unchanged.
struct SPKI: TrustChainNode, Sendable {
    /// The raw `subjectPublicKeyInfo` TLV from the certificate's DER encoding.
    let data: Data

    private init(data: Data) {
        self.data = data
    }

    static func extracted(from certificate: SecCertificate) -> Self? {
        guard let der = SecCertificateCopyData(certificate) as Data? else { return nil }
        guard let spki = der.subjectPublicKeyInfo else { return nil }
        return .init(data: spki)
    }
}

extension SPKI {
    /// Creates a node from a base64-encoded SPKI DER (e.g.
    /// `openssl x509 -noout -pubkey | openssl pkey -pubin -outform DER | base64`).
    init?(base64Encoded base64String: String) {
        guard let data = Data(base64Encoded: base64String),
              data.first == 0x30,
              let length = data.derLength(at: 0),
              length.headerSize + length.value == data.count else {
            return nil
        }
        self.init(data: data)
    }
}

/// Minimal DER reader for X.509 certificates.
/// DER is a tree of TLVs (Tag, Length, Value): the tag names the field,
/// the length makes it self-delimiting, the value holds nested TLVs.
extension Data {
    /// Decodes the length field of the DER TLV whose tag starts at `offset`.
    ///
    /// A DER TLV is laid out as `Tag ‖ Length ‖ Value` (X.690 §8.1).
    /// The tag occupies the byte at `offset`; the length field starts at
    /// `offset + 1` and comes in two forms (X.690 §8.1.3):
    ///
    /// - **Short form**: the high bit is clear and the byte itself is the
    ///   content length (0 … 127).
    /// - **Long form**: the high bit is set and the low 7 bits give `n`,
    ///   the number of following bytes holding the content length as a
    ///   big-endian integer (128 … 2^(8·n) − 1).
    ///
    /// Returns `(contentLength, headerByteCount)` where the header count
    /// includes the tag byte, so the next TLV starts at
    /// `offset + headerSize + contentLength`.
    ///
    /// Returns `nil` for truncated or malformed input — including more than
    /// four length bytes, which no real certificate field ever needs.
    func derLength(at offset: Int) -> (value: Int, headerSize: Int)? {
        let end = count

        // Need at least the tag byte and one length byte.
        guard offset + 1 < end else {
            return nil
        }

        let first = self[startIndex + offset + 1]

        // Short form: the length byte is the length itself.
        if first < 0x80 {
            return (Int(first), 2)
        }

        // Long form: low 7 bits = number of length bytes that follow.
        // Capped at 4 bytes: certificate fields are a few KB at most, so a
        // longer length field is malformed input, not a big certificate.
        let numBytes = Int(first & 0x7F)
        guard (1 ... 4).contains(numBytes),
              offset + 2 + numBytes <= end else {
            return nil
        }

        // Big-endian decode of the length bytes.
        var value = 0

        for index in 0 ..< numBytes {
            value = (value << 8) | Int(self[startIndex + offset + 2 + index])
        }

        return (value, 2 + numBytes)
    }

    /// The raw `subjectPublicKeyInfo` TLV embedded in a certificate's DER encoding.
    ///
    /// Rather than re-encoding the public key — which would require per-key-type
    /// knowledge (algorithm OID, curve, wrapping) — this slices the TLV exactly
    /// as the certificate presents it. That byte-faithful form is what SPKI
    /// digest pinning hashes, and it matches what
    /// `openssl x509 -noout -pubkey | openssl pkey -pubin -outform DER` emits.
    ///
    /// The walk follows the fixed field order of `tbsCertificate`
    /// (RFC 5280 §4.1.2.1):
    ///
    /// ```
    /// Certificate ::= SEQUENCE {
    ///     tbsCertificate SEQUENCE {
    ///         version        [0] EXPLICIT INTEGER   -- v3 certificates only
    ///         serialNumber   INTEGER
    ///         signature      AlgorithmIdentifier
    ///         issuer         Name
    ///         validity       Time
    ///         subject        Name
    ///         subjectPublicKeyInfo SEQUENCE         -- target
    ///         ...                                   -- not walked
    /// ```
    ///
    /// The walk is strict: any deviation from this layout (unexpected tag,
    /// truncated length, trailing bytes) yields `nil`. Extraction failing
    /// closed means a pin can never match against a misread certificate.
    var subjectPublicKeyInfo: Data? {
        let end = count

        /// Reads the tag byte at `offset`, or `nil` when past the end of the data.
        ///
        /// Indirecting the read keeps the walk total: every bounds check lives
        /// here and in `derLength(at:)`, so callers can compare tags with `==`
        /// without risking an out-of-bounds access on truncated input.
        func tag(at offset: Int) -> UInt8? {
            offset < end ? self[startIndex + offset] : nil
        }

        /// Skips the TLV at `offset`, advancing the cursor to the next field.
        ///
        /// Verifies that the field carries `expectedTag` (a structural check —
        /// a different tag means the data is not the certificate layout we
        /// assume) and that its length decodes, then moves `offset` past the
        /// tag, the length field and the content.
        ///
        /// Used for fields whose content we do not need.
        /// Returns `false` if the tag mismatches or the TLV is truncated.
        func skip(_ expectedTag: UInt8, at offset: inout Int) -> Bool {
            guard tag(at: offset) == expectedTag,
                  let length = derLength(at: offset) else {
                return false
            }

            offset += length.headerSize + length.value
            return offset <= end
        }

        // Certificate ::= SEQUENCE { tbsCertificate, signatureAlgorithm, signatureValue }
        guard tag(at: 0) == 0x30,
              let certificate = derLength(at: 0),
              certificate.headerSize + certificate.value == end else {
            return nil
        }

        var offset = certificate.headerSize

        // tbsCertificate ::= SEQUENCE
        guard tag(at: offset) == 0x30,
              let tbs = derLength(at: offset) else {
            return nil
        }

        offset += tbs.headerSize

        // version [0] EXPLICIT INTEGER — present only in v3 certificates
        if tag(at: offset) == 0xA0 {
            guard skip(0xA0, at: &offset) else {
                return nil
            }
        }
        // serialNumber, signature, issuer, validity, subject
        guard skip(0x02, at: &offset),
              skip(0x30, at: &offset),
              skip(0x30, at: &offset),
              skip(0x30, at: &offset),
              skip(0x30, at: &offset) else {
            return nil
        }

        // subjectPublicKeyInfo ::= SEQUENCE — the target field.
        // The complete raw TLV is taken (tag + length + content), not just the
        // content: SPKI digests must hash the structure exactly as the
        // certificate encodes it.
        guard tag(at: offset) == 0x30,
              let spki = derLength(at: offset) else {
            return nil
        }

        // Where the SPKI TLV ends within the certificate data.
        let spkiEnd = offset + spki.headerSize + spki.value

        guard spkiEnd <= end else {
            return nil
        }

        // A copy of the exact byte range (not a view into the original data).
        return subdata(in: (startIndex + offset) ..< (startIndex + spkiEnd))
    }
}
