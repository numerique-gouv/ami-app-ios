//
//  HandlePromotedNavigationUseCase.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 06/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Decides how a navigation to a promoted URL should be handled.
///
/// Does not perform the navigation itself — returns an
/// `AppRoute` for the presentation layer to execute.
struct HandlePromotedNavigationUseCase: Sendable {
    private let repository: any AliasedUrlsRepository

    init(repository: any AliasedUrlsRepository) {
        self.repository = repository
    }

    /// Resolves a pending navigation to a native screen.
    ///
    /// - Parameter url: the URL the web view is about to navigate to.
    /// - Returns: the route to open if the URL is a promoted destination
    ///   eligible for promotion; otherwise `nil` — the caller must not
    ///   intercept and the web page should navigate normally.
    func handle(url: URL) async throws -> AppRoute? {
        guard let promoted = try await repository.aliasedUrl(for: url) else {
            return nil
        }
        if case let .native(route) = promoted.destination {
            return route
        }
        return nil
    }
}
