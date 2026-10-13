//
//  AliasedUrlsDataModule.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum AliasedUrlsDataModule {
    /// Builds the repository around a host-supplied catalog provider.
    static func makeRepository(
        catalogProvider: @escaping ClosureAliasedUrlsDataSource.CatalogProvider
    ) -> any AliasedUrlsRepository {
        CachingAliasedUrlsRepository(dataSource: ClosureAliasedUrlsDataSource(catalogProvider: catalogProvider))
    }
}
