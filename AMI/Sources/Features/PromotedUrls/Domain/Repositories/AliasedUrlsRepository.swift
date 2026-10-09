//
//  AliasedUrlsRepository.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 06/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Gateway for aliased URL data.
///
/// The web page supplies alias/URL pairs; this repository combines them
/// with the local catalog (`PromotedAliases`) and produces entities whose
/// `destination` reflects local policy (alias route eligibility).
nonisolated protocol AliasedUrlsRepository: Sendable {
    /// Load the catalog of aliased urls from the data source (web page for instance).
    ///
    /// Pairs whose alias is not locally known are dropped. Each entity's
    /// `destination` is derived from the alias's route: `.native(route)`
    /// when eligible, `.webPage` otherwise.
    func fetchAliasedUrls() async throws -> [AliasedUrl]

    /// Resolves a navigation URL to an aliased URL if one matches.
    ///
    /// - Parameter url: the url the web page reported for the navigation.
    /// - Returns: the matching aliased URL, or `nil` if the alias is
    ///   unknown to the app.
    func aliasedUrl(for url: URL) async throws -> AliasedUrl?
}
