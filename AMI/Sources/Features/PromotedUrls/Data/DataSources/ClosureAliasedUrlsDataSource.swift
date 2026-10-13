//
//  ClosureAliasedUrlsDataSource.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// `AliasedUrlsDataSource` backed by a closure supplied by the host.
///
/// The host owns the mechanics of reading the catalog out of the web
/// page; the Data layer only sees the result.
struct ClosureAliasedUrlsDataSource: AliasedUrlsDataSource, Sendable {
    typealias CatalogProvider = @MainActor @Sendable () async throws(AliasedUrlsError) -> [AliasedUrlDTO]

    /// Called once per `fetchCatalog()`; must only be invoked when the
    /// page is fully loaded.
    private let catalogProvider: CatalogProvider

    init(catalogProvider: @escaping CatalogProvider) {
        self.catalogProvider = catalogProvider
    }

    func fetchCatalog() async throws(AliasedUrlsError) -> [AliasedUrlDTO] {
        try await catalogProvider()
    }
}
