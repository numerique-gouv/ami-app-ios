//
//  PromotedUrlsFeature.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Public entry point for the PromotedUrls feature.
///
/// Assembles the Data layer (around a host-supplied catalog provider),
/// the domain use cases, and the view model. The host:
/// - retains this feature,
/// - calls `viewModel.prepare()` when the page is fully loaded,
/// - calls `handleNavigation.handle(url:)` from its
///   `WKNavigationDelegate.decidePolicyFor`.
@MainActor
final class PromotedUrlsFeature {
    /// Feature runtime: readiness state and the loaded catalog.
    let viewModel: AliasedUrlsViewModel

    /// The navigation decision use case. Call from the web view's
    /// `decidePolicyFor`:
    ///
    /// ```swift
    /// guard action.navigationType == .linkActivated,
    ///       let url = action.request.url else { return .allow }
    /// guard let route = try? await feature.handleNavigation.handle(url: url)
    /// else { return .allow }
    /// open(route)
    /// return .cancel
    /// ```
    ///
    /// The two guards above are part of the contract: only link taps
    /// are intercepted, and any failure means "do not intercept".
    let handleNavigationUseCase: HandlePromotedNavigationUseCase

    /// Builds the feature around the host's catalog-reading closure.
    /// The closure is invoked by `viewModel.prepare()`, so it must only
    /// do real work once the page is fully loaded.
    init(catalogProvider: @escaping ClosureAliasedUrlsDataSource.CatalogProvider) {
        // Init AliasUrls repository.
        let repository: any AliasedUrlsRepository =
            AliasedUrlsDataModule.makeRepository(catalogProvider: catalogProvider)

        // Init AliasUrls fetcher.
        let getAliasedUrls = GetAliasedUrlsUseCase(repository: repository)

        // Init promoted url handling.
        let handleNavigation = HandlePromotedNavigationUseCase(repository: repository)
        handleNavigationUseCase = handleNavigation

        // Init promoted url viewmodel on which `prepare` will be called
        // when the source page is ready.
        viewModel = AliasedUrlsViewModel(getAliasedUrls: getAliasedUrls)
    }
}
