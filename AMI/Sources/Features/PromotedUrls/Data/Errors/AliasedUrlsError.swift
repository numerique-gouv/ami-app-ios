//
//  AliasedUrlsError.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum AliasedUrlsError: Error, Sendable {
    /// The web page failed to load or never became ready.
    case pageNotReady
    /// The page became ready but its payload was malformed or undecodable.
    case invalidPayload
}
