//
//  CertificatePinningTestHelpers.swift
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

// MARK: - SecTrust factory
//
// `SecTrustSetAnchorCertificatesOnly(trust, true)` makes the test CA the ONLY
// anchor for the trust object: the system trust store is invisible to the
// evaluation. That keeps every test hermetic — the outcome depends only on the
// fixtures, never on the machine the tests run on.

enum TrustFactory {
    /// A chain the evaluator will see, anchored exclusively to the test CA.
    /// `SecTrustEvaluateWithError` succeeds for it — and only for it.
    static func trust(_ chain: [SecCertificate],
                      anchoredBy ca: SecCertificate = TestCerts.ca) -> SecTrust {
        let trust = create(chain)
        SecTrustSetAnchorCertificates(trust, [ca] as CFArray)
        SecTrustSetAnchorCertificatesOnly(trust, true)
        return trust
    }

    /// A chain with NO usable anchor: `SecTrustEvaluateWithError` must fail for
    /// it, whatever the pins say.
    static func untrusted(_ chain: [SecCertificate]) -> SecTrust {
        create(chain)
    }

    private static func create(_ chain: [SecCertificate]) -> SecTrust {
        var created: SecTrust?
        let status = SecTrustCreateWithCertificates(chain as CFArray, nil, &created)
        precondition(status == errSecSuccess && created != nil,
                     "SecTrustCreateWithCertificates failed: \(status)")
        return created!
    }
}

// MARK: - Challenge factory
//
// `URLAuthenticationChallenge` instances are normally created by CFNetwork, but
// they can be built by hand: a `URLProtectionSpace` subclass that overrides
// `serverTrust` injects any `SecTrust` the tests want.

enum ChallengeFactory {
    final class StubProtectionSpace: URLProtectionSpace, @unchecked Sendable {
        private let storedTrust: SecTrust?

        init(host: String, trust: SecTrust?) {
            storedTrust = trust
            super.init(host: host, port: 443, protocol: "https", realm: nil,
                       authenticationMethod: NSURLAuthenticationMethodServerTrust)
        }

        override var serverTrust: SecTrust? { storedTrust }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("not used in tests") }
    }

    private final class StubChallengeSender: NSObject, URLAuthenticationChallengeSender {
        func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {}
        func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {}
        func cancel(_ challenge: URLAuthenticationChallenge) {}
    }

    /// A server-trust challenge carrying the given `SecTrust` (or none).
    static func challenge(host: String, trust: SecTrust?) -> URLAuthenticationChallenge {
        URLAuthenticationChallenge(protectionSpace: StubProtectionSpace(host: host, trust: trust),
                                   proposedCredential: nil, previousFailureCount: 0,
                                   failureResponse: nil, error: nil,
                                   sender: StubChallengeSender())
    }

    /// A challenge with a non-server-trust authentication method.
    static func nonServerTrustChallenge(host: String) -> URLAuthenticationChallenge {
        // Plain "httpPassword": anything that is not the server-trust method
        // must be left to the system by the feature.
        let space = URLProtectionSpace(host: host, port: 443, protocol: "https", realm: nil,
                                       authenticationMethod: "httpPassword")
        return URLAuthenticationChallenge(protectionSpace: space,
                                          proposedCredential: nil, previousFailureCount: 0,
                                          failureResponse: nil, error: nil,
                                          sender: StubChallengeSender())
    }
}

// swiftformat:enable all
// swiftlint:enable all
