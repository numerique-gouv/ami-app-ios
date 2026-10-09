//
//  AliasedUrlDTO.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Data carrier mirroring the alias/URL pairs the web page reports.
/// Shaped for decoding the catalog delivered by the host data source;
/// converted to the domain entity by the repository implementation.
struct AliasedUrlDTO: Decodable, Sendable {
    /// The alias exactly as the web page reports it (raw string — may
    /// not be known to the app).
    let alias: String
    /// The web destination suffix the page navigates to for this alias.
    let pattern: String
}
