//
//  PinRule.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct PinRule: Sendable {
    typealias SendablePinType = any Sendable & TrustChainNode

    let pattern: SendableRegex
    let pins: [SendablePinType]

    private init(pattern: SendableRegex, pins: [SendablePinType]) {
        self.pattern = pattern
        self.pins = pins
    }

    init(pattern: String, pins: [SendablePinType?]) {
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
