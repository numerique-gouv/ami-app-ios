//
//  AliasedUrlsDataSource.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Access point to the aliased URL catalog as stored by the web page.
///
/// `fetchCatalog` must be called by the host when the page is ready.
nonisolated protocol AliasedUrlsDataSource: Sendable {
    /// Fetch the aliased URLs catalog from the web page and returns the entries.
    /// - Throws `AliasedUrlsError.pageNotReady` if the page fails to load.
    /// - Throws `AliasedUrlsError.invalidPayload` if the payload is malformed.
    func fetchCatalog() async throws(AliasedUrlsError) -> [AliasedUrlDTO]
}
