//
//  RewriteUrlUseCase.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 27/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Decides which URL a navigation should load after the rules are applied.
nonisolated struct RewriteUrlUseCase: Sendable {
    /// Rules applied in this order. All rules whose host matches are applied
    /// (not first-match), so two independent concerns can tag the same host.
    let rules: [UrlRewriteRule]

    /// Returns the URL to load for the given navigation URL.
    ///
    /// - `nil`: no rule applies, or everything to add is already present —
    ///   load `url` as-is.
    /// - non-`nil`: always *different* from `url` (the use case never returns
    ///   its input).
    ///
    /// Matching is a whole-host regex match (case-insensitive by default),
    /// `http`/`https` only (ports and paths are not part of the match).
    ///
    /// Rewriting is idempotent: rewriting the returned URL a second time
    /// returns `nil`. That property is what prevents a
    /// `decidePolicyFor` cancel-and-reload loop.
    func rewrite(url: URL) -> URL? {
        guard url.scheme == "http" || url.scheme == "https",
              let host = url.host else {
            return nil
        }

        let matchingRules = rules.filter { $0.matches(host: host) }

        guard !matchingRules.isEmpty,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            // No matching rewrite rule found for this host or url is not parseable → don't intercept, load as-is
            return nil
        }

        var items = components.queryItems ?? []
        var changed = false

        for rule in matchingRules {
            // Only add query parameters. Don't overwrite existing ones.
            for (key, value) in rule.params where !items.contains(where: { $0.name == key }) {
                items.append(URLQueryItem(name: key, value: value))
                changed = true
            }
        }

        guard changed else {
            // Return nil if no change occur to tell the caller the URL wasn't modified (no new url returned).
            return nil
        }

        components.queryItems = items

        // Return the modified url.
        return components.url
    }
}
