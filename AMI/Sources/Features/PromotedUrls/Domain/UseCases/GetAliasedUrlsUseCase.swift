//
//  GetAliasedUrlsUseCase.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 06/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Loads the catalog of aliased URLs (alias + pattern +
/// navigation destination) from the data source.
struct GetAliasedUrlsUseCase: Sendable {
    private let repository: any AliasedUrlsRepository

    init(repository: any AliasedUrlsRepository) {
        self.repository = repository
    }

    /// Fetches the current catalog of aliased URLs.
    func fetch() async throws -> [AliasedUrl] {
        try await repository.fetchAliasedUrls()
    }
}
