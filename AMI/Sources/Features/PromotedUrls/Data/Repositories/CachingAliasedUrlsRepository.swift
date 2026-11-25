//
//  CachingAliasedUrlsRepository.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Caches the alias/URL catalog, combining the web page's catalog with
/// the local `PromotedAliases` catalog. Entries with unknown aliases are
/// dropped; each entity's destination is derived from the alias's route.
actor CachingAliasedUrlsRepository {
    private let dataSource: any AliasedUrlsDataSource
    private var catalog: [AliasedUrl]?

    init(dataSource: any AliasedUrlsDataSource) {
        self.dataSource = dataSource
    }

    func fetchAliasedUrls() async throws(AliasedUrlsError) -> [AliasedUrl] {
        try await ensureCatalogIsLoaded()
    }

    func aliasedUrl(for url: URL) async throws(AliasedUrlsError) -> AliasedUrl? {
        try await ensureCatalogIsLoaded().first {
            url.absoluteString.hasSuffix($0.pattern)
        }
    }

    // MARK: - Private

    /// Fetch the aliased url catalog if needed.
    /// An empty catalog is a valid loaded value if host provided an empty aliased urls list.
    private func ensureCatalogIsLoaded() async throws(AliasedUrlsError) -> [AliasedUrl] {
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

/// Conformance to the domain `AliasedUrlsRepository` role.
///
/// Declared in a separate extension, not on the actor definition line:
/// because of a bug in Swift 6.3 compiler in Release mode (`SWIFT_COMPILATION_MODE = wholemodule`).
/// An actor that declares conformance on its definition line to a protocol
/// explicitly marked `nonisolated` emits spurious diagnostics under whole-module optimization.
extension CachingAliasedUrlsRepository: AliasedUrlsRepository {}
