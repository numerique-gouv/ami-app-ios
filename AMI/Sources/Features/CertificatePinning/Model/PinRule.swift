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
