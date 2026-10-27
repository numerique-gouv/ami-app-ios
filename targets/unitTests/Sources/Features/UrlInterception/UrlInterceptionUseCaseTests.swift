//
//  UrlInterceptionUseCaseTests.swift
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
@Suite struct RewriteUrlUseCaseTests {
    private func url(_ s: String) -> URL { URL(string: s)! }

    @Test func addsMissingParamsInDeclarationOrder() throws {
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["src": "app", "v": "2"]),
        ])
        let out = useCase.rewrite(url: url("https://shop.example.com/checkout?ref=mail"))
        #expect(out?.absoluteString == "https://shop.example.com/checkout?ref=mail&src=app&v=2")
    }

    @Test func doesNotReplaceExistingParam() throws {
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["src": "app", "v": "2"]),
        ])
        // `src` already present (different value) → kept, only `v` added.
        let out = useCase.rewrite(url: url("https://shop.example.com/pay?src=web"))
        #expect(out?.absoluteString == "https://shop.example.com/pay?src=web&v=2")
    }

    @Test func returnsNilWhenNothingToAdd() throws {
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["src": "app", "v": "2"]),
        ])
        // Every key already present → the use case never returns its input.
        #expect(useCase.rewrite(url: url("https://shop.example.com/pay?src=web&v=9")) == nil)
    }

    @Test func appliesAllMatchingRulesInCatalogOrder() throws {
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["a": "1"]),
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["b": "2", "a": "9"]),
        ])
        // All matching rules apply; for a shared key the first declaration wins.
        let out = useCase.rewrite(url: url("https://shop.example.com/x"))
        #expect(out?.absoluteString == "https://shop.example.com/x?a=1&b=2")
    }

    @Test func rewriteIsIdempotent() throws {
        // Loop-safety invariant: the cancel-and-reload re-entry must be a no-op.
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: "shop\\.example\\.com", params: ["src": "app"]),
        ])
        let once = useCase.rewrite(url: url("https://shop.example.com/x"))
        #expect(once != nil)
        #expect(useCase.rewrite(url: once!) == nil)
    }

    @Test func ignoresNonHttpSchemes() throws {
        let useCase = RewriteUrlUseCase(rules: [
            try UrlRewriteRule(hostPattern: ".*", params: ["a": "1"]),
        ])
        #expect(useCase.rewrite(url: url("myapp://shop.example.com/open")) == nil)
        #expect(useCase.rewrite(url: url("javascript:alert(1)")) == nil)
    }

    @Test func emptyCatalogPassesEverythingThrough() {
        // Dark twin at the use-case level: no rules → never intercepts.
        let useCase = RewriteUrlUseCase(rules: [])
        #expect(useCase.rewrite(url: url("https://shop.example.com/x")) == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
