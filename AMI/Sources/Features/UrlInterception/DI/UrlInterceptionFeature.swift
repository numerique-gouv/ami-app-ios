//
//  UrlInterceptionFeature.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 27/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Entry point for the URL interception feature.
///
/// The host owns the `WKWebView` and its navigation delegate; it talks to this
/// feature exclusively through `rewriteUrl`, calling it inside `decidePolicyFor`:
///
/// ```swift
/// func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
///              decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
///     // Intercept user taps and page redirects only.
///     guard action.navigationType == .linkActivated || action.navigationType == .other
///     else { return decisionHandler(.allow) }
///
///     // WKWebView can't modify a URL in place: cancel, then load the rewritten
///     // one. `rewrite` is idempotent, so the reload's re-entry is a no-op.
///     guard let url = action.request.url,
///           let rewritten = feature.rewriteUrl.rewrite(url: url)
///     else { return decisionHandler(.allow) }   // no rule applies → never block
///
///     decisionHandler(.cancel)
///     webView.load(URLRequest(url: rewritten))
/// }
/// ```
///
/// Contract owned by the host: `.allow` is the default for everything this
/// feature doesn't explicitly claim (other navigation types, unparseable
/// inputs, non-http(s) URLs — the latter two are declined inside `rewrite`).
@MainActor
public final class UrlInterceptionFeature {
    /// The feature's only behavior: decide the URL to load for a navigation.
    let rewriteUrl: RewriteUrlUseCase

    init() {
        rewriteUrl = RewriteUrlUseCase(rules: Self.makeRules())
    }

    /// The active static rewrite catalog, in application order.
    ///
    /// An invalid pattern is a programmer error: `try!` makes it fail fast
    /// when the feature is constructed, instead of silently disabling a rule
    /// at match time. (Lives in a function rather than a `static let`:
    /// global variable initializers can't contain throwing expressions.)
    ///
    /// When the feature goes dynamic, this factory is replaced by a
    /// repository built here (and a `prepare()` added) — the use case, the
    /// host, and everything else stay untouched.
    private static func makeRules() -> [UrlRewriteRule] {
        // swiftlint:disable:next force_try
        try! [
            // .init(hostPattern: "shop\\.example\\.com", params: ["src": "app", "v": "1"]),
            // .init(hostPattern: "docs\\.example\\.com", params: ["ref": "ios"]),
            .init(hostPattern: "(.+\\.)?service-public\\.gouv\\.fr", params: ["view": "mobile"]),
            .init(hostPattern: "www\\.masecurite-form\\.pp\\.gendarmerie\\.interieur\\.gouv\\.fr", params: ["view": "mobile"]),
        ]
    }
}
