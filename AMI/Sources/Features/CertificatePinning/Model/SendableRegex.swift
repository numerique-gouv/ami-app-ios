//
//  SendableRegex.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 18/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Only use with regexes that contain no custom components or transform closures
/// (plain literals or Regex(String)).
///
/// `Regex` is not `Sendable`; a plain literal or string-built regex holds
/// no state beyond its pattern, so the wrapper is transfer-safe under
/// that restriction.
struct SendableRegex: @unchecked Sendable {
    let regex: Regex<AnyRegexOutput>

    init(_ regex: Regex<AnyRegexOutput>) {
        self.regex = regex
    }
}
