//
//  AliasedUrlsViewModel.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import Observation

/// Owns the PromotedUrls feature's runtime: readiness and
/// the loaded catalog.
///
/// The host web view controller creates it once and calls
/// `prepare()` from its existing "page fully loaded" event.
@MainActor
@Observable
final class AliasedUrlsViewModel {
    enum Readiness: Equatable {
        /// `prepare()` not yet called (page not ready yet).
        case uninitialized
        /// Catalog loaded; promoted navigations are intercepted.
        case ready
        /// Catalog could not be loaded. The feature degrades: all
        /// navigations pass through to the web page.
        case failed
    }

    private(set) var readiness: Readiness = .uninitialized
    private(set) var aliasedUrls: [AliasedUrl] = []

    private let getAliasedUrls: GetAliasedUrlsUseCase

    init(getAliasedUrls: GetAliasedUrlsUseCase) {
        self.getAliasedUrls = getAliasedUrls
    }

    /// Loads the aliased URL catalog. Call once, when the web page
    /// reports it is fully loaded.
    ///
    /// On failure the feature enters `.failed` and every navigation
    /// passes through — a load error must never break the web page.
    func prepare() async {
        do {
            aliasedUrls = try await getAliasedUrls.fetch()
            readiness = .ready
        } catch {
            readiness = .failed
        }
    }
}
