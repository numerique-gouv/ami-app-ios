//
//  CachingAliasedUrlsRepository.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// `AliasedUrlsRepository` backed by a `AliasedUrlsDataSource`.
///
/// Combines the web page's alias/URL catalog with the local
/// `PromotedAliases` catalog. Entries with unknown aliases are dropped;
/// each entity's destination is derived from the alias's route.
actor CachingAliasedUrlsRepository: AliasedUrlsRepository {
    private let dataSource: any AliasedUrlsDataSource
    private var catalog: [AliasedUrl]?

    init(dataSource: any AliasedUrlsDataSource) {
        self.dataSource = dataSource
    }

    func fetchAliasedUrls() async throws -> [AliasedUrl] {
        try await ensureCatalogIsLoaded()
    }

    func aliasedUrl(for url: URL) async throws -> AliasedUrl? {
        try await ensureCatalogIsLoaded().first {
            url.absoluteString.hasSuffix($0.pattern)
        }
    }

    // MARK: - Private

    /// Fetch the aliased url catalog if needed.
    /// An empty catalog is a valid loaded value if host provided an empty aliased urls list.
    private func ensureCatalogIsLoaded() async throws -> [AliasedUrl] {
        if let catalog {
            return catalog
        }
        let dtos = try await dataSource.fetchCatalog()
        let mappedCatalog = Self.map(dtos)
        catalog = mappedCatalog
        return mappedCatalog
    }

    /// Maps web-provided DTOs to domain entities, dropping unknown aliases.
    private static func map(_ dtos: [AliasedUrlDTO]) -> [AliasedUrl] {
        dtos.compactMap { dto in
            guard !dto.pattern.isEmpty, // Verify Alias pattern is not empty.
                  dto.pattern.starts(with: "/"), // Verify Alias pattern starts with a slash.
                  let alias = PromotedAliases(rawValue: dto.alias) else {
                return nil
            }
            return AliasedUrl(pattern: dto.pattern,
                              alias: alias,
                              // Get defined route for alias, fallback to `.webPage` when the alias has no route (nil).
                              destination: alias.route.map { .native($0) } ?? .webPage)
        }
    }
}
