//
//  UrlInterceptionFeatureTests.swift
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
@Suite struct UrlInterceptionFeatureTests {
    /// Constructing the feature runs `try!` over the whole catalog: a pattern
    /// that doesn't compile crashes the local test run — programmer errors
    /// die here, not in production.
    @Test func constructionValidatesWholeCatalog() {
        _ = UrlInterceptionFeature()
    }

    /// Pin for the shipped rule: fails if the pattern compiles but matches
    /// nothing (a typo), with and without a subdomain.
    @Test func catalogServicePublicRuleAddsViewParam() {
        let feature = UrlInterceptionFeature()
        for host in ["service-public.gouv.fr", "www.service-public.gouv.fr"] {
            let out = feature.rewriteUrl.rewrite(url: URL(string: "https://\(host)/particuliers/12345")!)
            let queryItems = out.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems }
            #expect(queryItems?.contains { $0.name == "view" && $0.value == "mobile" } == true)
        }
    }

    @Test func unmatchedHostPassesThrough() {
        let feature = UrlInterceptionFeature()
        #expect(feature.rewriteUrl.rewrite(url: URL(string: "https://example.com/")!) == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
