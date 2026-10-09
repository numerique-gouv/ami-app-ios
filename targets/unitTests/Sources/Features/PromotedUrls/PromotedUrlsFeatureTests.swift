//
//  PromotedUrlsFeatureTests.swift
//
//  In-memory end-to-end tests through `PromotedUrlsFeature`, plus the
//  view model readiness states.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Observation
import Testing

@testable import AMI_Staging

@Suite("PromotedUrlsFeature — end to end")
@MainActor
struct PromotedUrlsFeatureTests {
    private let promotedURL = URL(
        string: "https://app.ami.fr/preferences/notifications/activation"
    )!

    private func makeFeature(
        provider: @escaping @MainActor @Sendable () async throws(AliasedUrlsError) -> [AliasedUrlDTO]
    ) -> PromotedUrlsFeature {
        PromotedUrlsFeature(catalogProvider: provider)
    }

    @Test func promotedNavigationIsResolvedToRoute() async {
        let feature = makeFeature(provider: {
            [
                AliasedUrlDTO(alias: "preferences:notifications:activation",
                              pattern: "/preferences/notifications/activation"),
            ]
        })

        await feature.viewModel.prepare()
        #expect(feature.viewModel.readiness == .ready)

        let route = try? await feature.handleNavigationUseCase.handle(url: promotedURL)
        #expect(route == .amiNotificationsSettings)
    }

    @Test func featureDegradesWhenCatalogCannotLoad() async {
        // Core contract: a load failure must never break the page —
        // every navigation resolves to "do not intercept".
        let feature = makeFeature(provider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
            throw AliasedUrlsError.pageNotReady })

        await feature.viewModel.prepare()
        #expect(feature.viewModel.readiness == .failed)
        #expect(feature.viewModel.aliasedUrls.isEmpty)

        let route = try? await feature.handleNavigationUseCase.handle(url: promotedURL)
        #expect(route == nil)
    }
}

@Suite("AliasedUrlsViewModel — readiness")
@MainActor
struct AliasedUrlsViewModelTests {
    private func makeViewModel(
        provider: @escaping @MainActor @Sendable () async throws(AliasedUrlsError) -> [AliasedUrlDTO]
    ) -> AliasedUrlsViewModel {
        let repository: any AliasedUrlsRepository = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: provider)
        )
        return AliasedUrlsViewModel(
            getAliasedUrls: GetAliasedUrlsUseCase(repository: repository)
        )
    }

    @Test func startsUninitialized() {
        let viewModel = makeViewModel(provider: { [] })
        #expect(viewModel.readiness == .uninitialized)
    }

    @Test func prepareSuccessPopulatesCatalog() async {
        let viewModel = makeViewModel(provider: {
            [
                AliasedUrlDTO(alias: "preferences:notifications:activation",
                              pattern: "/preferences/notifications/activation"),
            ]
        })

        await viewModel.prepare()

        #expect(viewModel.readiness == .ready)
        #expect(viewModel.aliasedUrls.count == 1)
    }

    @Test func prepareFailureEntersFailedState() async {
        let viewModel = makeViewModel(provider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
            throw AliasedUrlsError.invalidPayload })

        await viewModel.prepare()

        #expect(viewModel.readiness == .failed)
        #expect(viewModel.aliasedUrls.isEmpty)
    }

    @Test func prepareRetriesAfterFailure() async {
        // The repository does not cache failures, so a second
        // `prepare()` after a recovered page must heal the feature.
        var attempt = 0
        let viewModel = makeViewModel(provider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
            attempt += 1
            if attempt == 1 { throw AliasedUrlsError.pageNotReady }
            return [
                AliasedUrlDTO(alias: "preferences:notifications:activation",
                              pattern: "/preferences/notifications/activation"),
            ]
        })

        await viewModel.prepare()
        #expect(viewModel.readiness == .failed)

        await viewModel.prepare()
        #expect(viewModel.readiness == .ready)
        #expect(viewModel.aliasedUrls.count == 1)
    }
}

// swiftformat:enable all
// swiftlint:enable all
