//
//  UrlRewriteRule.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 27/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Business rule applied to navigated URLs whose host matches the regex.
///
/// Pure data on purpose: the same type can later be built from a remote
/// catalog (Data layer) without touching the use case.
nonisolated struct UrlRewriteRule: Sendable {
    /// Regular expression the URL host must match in its entirety.
    /// Literal characters must be escaped (e.g. `"shop\\.example\\.com"`);
    /// no `^`/`$` needed — the match is always whole-host.
    let hostPattern: String

    /// Query parameters to add when the URL doesn't already carry the key.
    /// Insertion order is preserved in the rewritten URL.
    let params: KeyValuePairs<String, String>

    /// Pre-compiled `hostPattern` (case-insensitive), matched whole.
    private let hostRegex: Regex<AnyRegexOutput>

    /// Creates a rule, compiling `hostPattern`.
    ///
    /// - Throws: if `hostPattern` is not a valid regular expression. The
    ///   static catalog wraps construction in `try!` (programmer error →
    ///   crash at startup); a future dynamic mapping drops rules that throw.
    init(hostPattern: String, params: KeyValuePairs<String, String>) throws {
        self.hostPattern = hostPattern
        self.params = params
        hostRegex = try Regex(hostPattern).ignoresCase()
    }

    /// Whole-host, case-insensitive match (a pattern can opt into
    /// case-sensitivity with an inline `(?-i)` flag).
    func matches(host: String) -> Bool {
        host.wholeMatch(of: hostRegex) != nil
    }
}
