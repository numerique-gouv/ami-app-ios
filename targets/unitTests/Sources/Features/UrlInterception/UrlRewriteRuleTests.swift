//
//  UrlRewriteRuleTests.swift
//  AMI-UnitTests
//
//  Created by Nicolas Buquet on 27/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

@MainActor
@Suite struct UrlRewriteRuleTests {
    @Test func invalidPatternThrows() {
        #expect(throws: Error.self) {
            try UrlRewriteRule(hostPattern: "(", params: [:])
        }
    }

    @Test func matchesWholeHostCaseInsensitively() throws {
        let rule = try UrlRewriteRule(hostPattern: "Example\\.COM", params: [:])
        #expect(rule.matches(host: "example.com"))
        #expect(rule.matches(host: "EXAMPLE.COM"))
    }

    @Test func doesNotMatchPartialHost() throws {
        let rule = try UrlRewriteRule(hostPattern: "example\\.com", params: [:])
        #expect(!rule.matches(host: "notexample.com"))
        #expect(!rule.matches(host: "example.com.evil.net"))
    }

    @Test func subdomainWildcardMatchesAnyDepth() throws {
        let rule = try UrlRewriteRule(hostPattern: ".*\\.example\\.com", params: [:])
        #expect(rule.matches(host: "www.example.com"))
        #expect(rule.matches(host: "a.b.example.com"))
        #expect(!rule.matches(host: "example.com"))  // bare domain: wildcard requires a subdomain
    }
}

// swiftformat:enable all
// swiftlint:enable all
