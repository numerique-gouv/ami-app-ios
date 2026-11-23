//
//  PinFactory.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import CryptoKit
import Foundation

/// Hash algorithm selectable for pin creation.
enum PinHashingAlgorithmType {
    case sha256
    case sha384
    case sha512
    @available(iOS 26.0, *) case sha3_256
    @available(iOS 26.0, *) case sha3_384
    @available(iOS 26.0, *) case sha3_512
}

/// Key type for `.publicKey` pins.
enum PublicKeyType {
    case p256
    case p384
    case p521
    case rsa
}

/// Builds `SendableTrustChainNode` pins from base64 representations.
///
/// `algorithm == nil` yields the unhashed node itself (whole certificate,
/// raw key, or raw SPKI). Returns `nil` for a malformed representation or
/// an algorithm unavailable on this OS (SHA-3 before iOS 26); `PinRule`
/// turns a nil pin into a build-time precondition failure.
enum PinFactory {
    case certificate
    case publicKey(PublicKeyType)
    case spki

    func makePin(algorithm: PinHashingAlgorithmType? = nil, base64Representation: String) -> (any SendableTrustChainNode)? {
        switch self {
        case .certificate: makeCertificatePin(algorithm: algorithm, base64Representation: base64Representation)
        case .publicKey(.p256): makePublicKeyPin(keyType: .p256, algorithm: algorithm, base64Representation: base64Representation)
        case .publicKey(.p384): makePublicKeyPin(keyType: .p384, algorithm: algorithm, base64Representation: base64Representation)
        case .publicKey(.p521): makePublicKeyPin(keyType: .p521, algorithm: algorithm, base64Representation: base64Representation)
        case .publicKey(.rsa): makePublicKeyPin(keyType: .rsa, algorithm: algorithm, base64Representation: base64Representation)
        case .spki: makeSpkiPin(algorithm: algorithm, base64Representation: base64Representation)
        }
    }

    // Certificates
    private func makeCertificatePin(algorithm: PinHashingAlgorithmType? = nil, base64Representation: String) -> (any SendableTrustChainNode)? {
        switch algorithm {
        case .none: Certificate(base64Encoded: base64Representation)
        case .sha256: HashedPin<Certificate, SHA256>(base64Encoded: base64Representation)
        case .sha384: HashedPin<Certificate, SHA384>(base64Encoded: base64Representation)
        case .sha512: HashedPin<Certificate, SHA512>(base64Encoded: base64Representation)
        case .sha3_256: if #available(iOS 26.0, *) {
                HashedPin<Certificate, SHA3_256>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_384: if #available(iOS 26.0, *) {
                HashedPin<Certificate, SHA3_384>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_512: if #available(iOS 26.0, *) {
                HashedPin<Certificate, SHA3_512>(base64Encoded: base64Representation)
            } else {
                nil
            }
        }
    }

    // Public keys EC-P256, EC-P384, EC-P521, RSA
    // swiftlint:disable:next cyclomatic_complexity
    private func makePublicKeyPin(keyType: PublicKeyType, algorithm: PinHashingAlgorithmType? = nil, base64Representation: String) -> (any SendableTrustChainNode)? {
        switch algorithm {
        case .none:
            switch keyType {
            case .p256: PublicKey(from: P256.Signing.PublicKey(base64Encoded: base64Representation))
            case .p384: PublicKey(from: P384.Signing.PublicKey(base64Encoded: base64Representation))
            case .p521: PublicKey(from: P521.Signing.PublicKey(base64Encoded: base64Representation))
            case .rsa: PublicKey(from: RSA.Signing.PublicKey(base64Encoded: base64Representation))
            }
        case .sha256: HashedPin<PublicKey, SHA256>(base64Encoded: base64Representation)
        case .sha384: HashedPin<PublicKey, SHA384>(base64Encoded: base64Representation)
        case .sha512: HashedPin<PublicKey, SHA512>(base64Encoded: base64Representation)
        case .sha3_256: if #available(iOS 26.0, *) {
                HashedPin<PublicKey, SHA3_256>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_384: if #available(iOS 26.0, *) {
                HashedPin<PublicKey, SHA3_384>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_512: if #available(iOS 26.0, *) {
                HashedPin<PublicKey, SHA3_512>(base64Encoded: base64Representation)
            } else {
                nil
            }
        }
    }

    // SPKI keys
    private func makeSpkiPin(algorithm: PinHashingAlgorithmType? = nil, base64Representation: String) -> (any SendableTrustChainNode)? {
        switch algorithm {
        case .none: SPKI(base64Encoded: base64Representation)
        case .sha256: HashedPin<SPKI, SHA256>(base64Encoded: base64Representation)
        case .sha384: HashedPin<SPKI, SHA384>(base64Encoded: base64Representation)
        case .sha512: HashedPin<SPKI, SHA512>(base64Encoded: base64Representation)
        case .sha3_256: if #available(iOS 26.0, *) {
                HashedPin<SPKI, SHA3_256>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_384: if #available(iOS 26.0, *) {
                HashedPin<SPKI, SHA3_384>(base64Encoded: base64Representation)
            } else {
                nil
            }
        case .sha3_512: if #available(iOS 26.0, *) {
                HashedPin<SPKI, SHA3_512>(base64Encoded: base64Representation)
            } else {
                nil
            }
        }
    }
}
