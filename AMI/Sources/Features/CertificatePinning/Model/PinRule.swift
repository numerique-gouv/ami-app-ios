//
//  PinRule.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Associates a host pattern with the pins accepted for matching hosts.
///
/// The pattern is a case-insensitive, whole-match regex over the host
/// (a port is never part of the host). A matching host is accepted only
/// if at least one pin matches a certificate in its validated chain.
///
/// Creation fails fast on an uncompilable pattern or a pin that failed to
/// build: an app with a broken pin set must not start.
struct PinRule: Sendable {
    typealias SendablePinType = any Sendable & TrustChainNode

    let pattern: SendableRegex
    let pins: [SendablePinType]

    private init(pattern: SendableRegex, pins: [SendablePinType]) {
        self.pattern = pattern
        self.pins = pins
    }

    /// Creates a pin rule.
    ///
    /// `pattern` is a case-insensitive regex matched against the host as a
    /// whole match (`wholeMatch`), so the engine already requires the entire
    /// hostname to match. It is still recommended to anchor the pattern —
    /// start with `^` and end with `$` — to make that intent explicit and keep
    /// it correct if matching ever changes from `wholeMatch` to a substring
    /// match; an unanchored pattern is fragile and can match unintended hosts.
    ///
    /// `pins` elements are optional to ease the call site: each pin can be
    /// built with a failable initializer and passed directly, with no
    /// unwrapping or validation up front. If any element is `nil`, the
    /// initializer fails fast (`preconditionFailure`) and stops execution: an
    /// app with a broken pin set must not start.
    init(pattern: String, pins: [SendablePinType?]) {
        // Hostnames are caseless (RFC 4343): force case-insensitive matching,
        // so a mixed-case host (e.g. "WWW.Example.COM") can never silently
        // miss its pin rule and degrade to system-default handling.
        guard let regexPattern = try? Regex(pattern).ignoresCase() else {
            // Application must not start if domain regular expression is not compilable.
            preconditionFailure("Error creating PinRule Regular Expression from pattern: \"\(pattern)\"")
        }
        let compactedPins = pins.compactMap(\.self)
        guard compactedPins.count > 0,
              compactedPins.count == pins.count else {
            // Application must not start if any pin failed to build.
            preconditionFailure("Error creating PinRule pins: some pins are nil.")
        }

        self.init(pattern: SendableRegex(regexPattern), pins: compactedPins)
    }
}
