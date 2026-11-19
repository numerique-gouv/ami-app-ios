//
//  PinRuleHostMatchingTests.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 19/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

// MARK: - Host matching
//
// `PinRule` selects its pins with `pattern.regex.wholeMatch(in: host)` — the
// same expression `ServerTrustEvaluator` uses. This table is a black box on
// that expression with the production cloudflare pattern, and it is the guard
// against suffix/typo attacks on the domain patterns.

@Suite("PinRule host matching")
struct PinRuleHostMatchingTests {

    private static let cloudflareRule = PinRule(pattern: "^(.+\\.)?cloudflare\\.com$", pins: [
        PinFactory.spki.makePin(algorithm: .sha256, base64Representation: Goldens.ecP256SpkiSha256),
    ])

    /// The exact selection the evaluator performs.
    private static func selectsPins(forHost host: String) -> Bool {
        (try? cloudflareRule.pattern.regex.wholeMatch(in: host)) != nil
    }

    @Test func acceptedHosts() {
        let hosts = [
            "cloudflare.com",
            "www.cloudflare.com",
            "api.sub.cloudflare.com",
            "WWW.CLOUDFLARE.COM",      // DNS names are case-insensitive
            "Sub.Cloudflare.com",
        ]
        for host in hosts {
            #expect(Self.selectsPins(forHost: host), "should accept \(host)")
        }
    }

    @Test func rejectedHosts() {
        let hosts = [
            "notcloudflare.com",        // prefix attack
            "xcloudflare.com",          // no dot separator
            "cloudflare.com.evil.com",  // suffix attack
            "cloudflare.com:443",       // host is never given a port
            "cloudflare.fr",            // different TLD
            "cloudflarecom",            // missing dot
            "",
        ]
        for host in hosts {
            #expect(!Self.selectsPins(forHost: host), "should reject \(host)")
        }
    }
}

// swiftformat:enable all
// swiftlint:enable all
