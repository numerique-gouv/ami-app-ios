//
//  CachingAliasedUrlsRepositoryTests.swift
//
//  Tests the caching repository through its public API, using
//  `ClosureAliasedUrlsDataSource` as the in-memory test double.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

@Suite("CachingAliasedUrlsRepository — mapping guards")
struct MappingGuardsTests {
    /// Builds a repository whose provider returns the given DTOs.
    private func repository(with dtos: [AliasedUrlDTO]) -> CachingAliasedUrlsRepository {
        CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { dtos })
        )
    }

    private let validDTO = AliasedUrlDTO(
        alias: "preferences:notifications:activation",
        pattern: "/preferences/notifications/activation"
    )

    @Test func knownAliasWithRouteGetsNativeDestination() async throws {
        let repo = repository(with: [validDTO])
        let catalog = try await repo.fetchAliasedUrls()

        #expect(catalog.count == 1)
        #expect(catalog.first?.destination == .native(.amiNotificationsSettings))
    }

    @Test func knownAliasWithoutRouteGetsWebPageDestination() async throws {
        let repo = repository(with: [
            AliasedUrlDTO(alias: "welcome:notifications:activation",
                          pattern: "/welcome/notifications/activation"),
        ])
        let catalog = try await repo.fetchAliasedUrls()

        #expect(catalog.count == 1)
        #expect(catalog.first?.destination == .webPage)
    }

    @Test func unknownAliasIsDropped() async throws {
        let repo = repository(with: [
            AliasedUrlDTO(alias: "not:known:to:app",
                          pattern: "/not/known"),
        ])
        #expect(try await repo.fetchAliasedUrls().isEmpty)
    }

    @Test func emptyPatternIsDropped() async throws {
        let repo = repository(with: [
            AliasedUrlDTO(alias: "preferences:notifications:activation",
                          pattern: ""),
        ])
        #expect(try await repo.fetchAliasedUrls().isEmpty)
    }

    @Test func patternWithoutLeadingSlashIsDropped() async throws {
        // Without the leading slash, `hasSuffix("")`-style bleed would
        // match far more than intended
        // `preferences/...` could math `/mypreferences/...`.
        let repo = repository(with: [
            AliasedUrlDTO(alias: "preferences:notifications:activation",
                          pattern: "preferences/notifications/activation"),
        ])
        #expect(try await repo.fetchAliasedUrls().isEmpty)
    }

    @Test func mixedCatalogKeepsOnlyValidEntriesInOrder() async throws {
        let repo = repository(with: [
            AliasedUrlDTO(alias: "not:known", pattern: "/nope"),
            validDTO,
            AliasedUrlDTO(alias: "welcome:notifications:activation", pattern: ""),
            AliasedUrlDTO(alias: "welcome:notifications:activation",
                          pattern: "/welcome/notifications/activation"),
        ])
        let catalog = try await repo.fetchAliasedUrls()

        #expect(catalog.count == 2)
        #expect(catalog[0].alias == .preferencesNotificationsActivation)
        #expect(catalog[1].alias == .welcomeNotificationsActivation)
    }
}

@Suite("CachingAliasedUrlsRepository — suffix matching")
struct SuffixMatchingTests {
    private let pattern = "/preferences/notifications/activation"
    private func repository() -> CachingAliasedUrlsRepository {
        CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: {
                [
                    AliasedUrlDTO(alias: "preferences:notifications:activation",
                                  pattern: pattern),
                ]
            })
        )
    }

    private func url(_ absoluteString: String) -> URL {
        URL(string: absoluteString)!
    }

    @Test func exactSuffixMatches() async throws {
        let repo = repository()
        let match = try await repo.aliasedUrl(
            for: url("https://app.ami.fr/preferences/notifications/activation")
        )
        #expect(match?.alias == .preferencesNotificationsActivation)
    }

    @Test func hostDoNotBreakMatching() async throws {
        let repo = repository()
        let match = try await repo.aliasedUrl(
            for: url("https://app.ami.fr/deep/path/preferences/notifications/activation")
        )
        #expect(match != nil)
    }

    @Test func trailingQueryParametersDoNotMatch() async throws {
        let repo = repository()
        let match = try await repo.aliasedUrl(
            for: url("/deep/path/preferences/notifications/activation?utm_source=x")
        )
        #expect(match == nil)
    }

    @Test func nonMatchingUrlReturnsNil() async throws {
        let repo = repository()
        #expect(try await repo.aliasedUrl(for: url("https://app.ami.fr/other/page")) == nil)
    }

    @Test func leadingSlashPreventsSuffixBleed() async throws {
        // `/xpreferences/...` must NOT match `/preferences/...` —
        // the leading slash of the pattern aligns on a path boundary.
        let repo = repository()
        let bleed = try await repo.aliasedUrl(
            for: url("https://app.ami.fr/xpreferences/notifications/activation")
        )
        #expect(bleed == nil)
    }

    @Test func firstCatalogEntryWinsOnMultipleMatches() async throws {
        let repo = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: {
                [
                    AliasedUrlDTO(alias: "preferences:notifications:activation",
                                  pattern: "/activation"),
                    AliasedUrlDTO(alias: "welcome:notifications:activation",
                                  pattern: "/welcome/notifications/activation"),
                ]
            })
        )
        let match = try await repo.aliasedUrl(
            for: url("https://app.ami.fr/welcome/notifications/activation")
        )
        // Both patterns suffix-match; load order decides.
        #expect(match?.alias == .preferencesNotificationsActivation)
    }
}

@Suite("CachingAliasedUrlsRepository — cache behavior")
@MainActor
struct CacheBehaviorTests {
    @Test func providerIsCalledOnlyOnceAcrossLookups() async throws {
        var calls = 0
        let repo = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: {
                calls += 1
                return [
                    AliasedUrlDTO(alias: "preferences:notifications:activation",
                                  pattern: "/preferences/notifications/activation"),
                ]
            })
        )

        _ = try await repo.fetchAliasedUrls()
        _ = try await repo.aliasedUrl(for: URL(string: "https://x.fr/whatever")!)
        _ = try await repo.fetchAliasedUrls()

        #expect(calls == 1)
    }

    @Test func emptyCatalogIsCached() async throws {
        // An empty catalog is a valid loaded value: the provider must not
        // be re-invoked on subsequent calls.
        var calls = 0
        let repo = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: {
                calls += 1
                return [AliasedUrlDTO]()
            })
        )

        #expect(try await repo.fetchAliasedUrls().isEmpty)
        #expect(try await repo.fetchAliasedUrls().isEmpty)

        #expect(calls == 1)
    }

    @Test func failureIsNotCached() async throws {
        // First call fails, second recovers: the failed load must not be
        // cached, so a later lookup can heal the catalog.
        var attempt = 0
        let repo = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
                attempt += 1
                if attempt == 1 { throw AliasedUrlsError.pageNotReady }
                return [
                    AliasedUrlDTO(alias: "preferences:notifications:activation",
                                  pattern: "/preferences/notifications/activation"),
                ]
            })
        )

        await #expect(throws: AliasedUrlsError.pageNotReady) {
            _ = try await repo.fetchAliasedUrls()
        }

        let match = try await repo.aliasedUrl(
            for: URL(string: "https://app.ami.fr/preferences/notifications/activation")!
        )
        #expect(match?.alias == .preferencesNotificationsActivation)
        #expect(attempt == 2)
    }
}

// swiftformat:enable all
// swiftlint:enable all
