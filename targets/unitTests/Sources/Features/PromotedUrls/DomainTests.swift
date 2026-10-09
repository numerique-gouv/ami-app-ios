//
//  DomainTests.swift
//
//  Domain-layer tests: aliases, entity, DTO, and the two use cases.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

@Suite("PromotedAliases")
struct PromotedAliasesTests {
    @Test func rawValueRoundTrip() {
        #expect(PromotedAliases(rawValue: "welcome:notifications:activation")
            == .welcomeNotificationsActivation)
        #expect(PromotedAliases(rawValue: "preferences:notifications:activation")
            == .preferencesNotificationsActivation)
    }

    @Test func unknownRawValueIsNil() {
        #expect(PromotedAliases(rawValue: "garbage") == nil)
        #expect(PromotedAliases(rawValue: "") == nil)
    }

    @Test func routeMapping() {
        #expect(PromotedAliases.welcomeNotificationsActivation.route == nil)
        #expect(PromotedAliases.preferencesNotificationsActivation.route
            == .amiNotificationsSettings)
    }
}

@Suite("AliasedUrl")
struct AliasedUrlTests {
    private func make(_ pattern: String,
                      _ destination: AliasedUrl.Destination) -> AliasedUrl {
        AliasedUrl(pattern: pattern,
                   alias: .preferencesNotificationsActivation,
                   destination: destination)
    }

    @Test func equalityIsAliasOnly() {
        let first = make("/a/b", .native(.amiNotificationsSettings))
        let second = make("/completely/different", .webPage)

        #expect(first == second)
    }
}

@Suite("AliasedUrlDTO")
struct AliasedUrlDTOTests {
    @Test func decodesValidPayload() throws {
        let json = #"{ "alias": "preferences:notifications:activation", "pattern": "/preferences/notifications/activation" }"#
        let dto = try JSONDecoder().decode(AliasedUrlDTO.self, from: Data(json.utf8))

        #expect(dto.alias == "preferences:notifications:activation")
        #expect(dto.pattern == "/preferences/notifications/activation")
    }

    @Test func decodesArrayPayload() throws {
        let json = #"[{ "alias": "a:b", "pattern": "/a/b" }, { "alias": "c:d", "pattern": "/c/d" }]"#
        let dtos = try JSONDecoder().decode([AliasedUrlDTO].self, from: Data(json.utf8))

        #expect(dtos.count == 2)
    }

    @Test func missingKeyFailsDecoding() {
        let json = #"{ "alias": "a:b" }"#
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(AliasedUrlDTO.self, from: Data(json.utf8))
        }
    }
}

@Suite("HandlePromotedNavigationUseCase")
struct HandlePromotedNavigationUseCaseTests {
    private func useCase(with dtos: [AliasedUrlDTO]) -> HandlePromotedNavigationUseCase {
        let repository: any AliasedUrlsRepository = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { dtos })
        )
        return HandlePromotedNavigationUseCase(repository: repository)
    }

    private let url = URL(string: "https://app.ami.fr/preferences/notifications/activation")!

    @Test func eligibleAliasReturnsRoute() async throws {
        let useCase = useCase(with: [
            AliasedUrlDTO(alias: "preferences:notifications:activation",
                          pattern: "/preferences/notifications/activation"),
        ])
        #expect(try await useCase.handle(url: url) == .amiNotificationsSettings)
    }

    @Test func knownButIneligibleAliasReturnsNil() async throws {
        let useCase = useCase(with: [
            AliasedUrlDTO(alias: "welcome:notifications:activation",
                          pattern: "/welcome/notifications/activation"),
        ])
        #expect(try await useCase.handle(
            url: URL(string: "https://app.ami.fr/welcome/notifications/activation")!
        ) == nil)
    }

    @Test func nonMatchingUrlReturnsNil() async throws {
        let useCase = useCase(with: [
            AliasedUrlDTO(alias: "preferences:notifications:activation",
                          pattern: "/preferences/notifications/activation"),
        ])
        #expect(try await useCase.handle(url: URL(string: "https://app.ami.fr/other")!) == nil)
    }

    @Test func repositoryErrorPropagates() async {
        // The use case must throw (not swallow); degrading to `.allow`
        // is the *caller's* decision via `try?`.
        let repository: any AliasedUrlsRepository = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
                throw AliasedUrlsError.invalidPayload
            })
        )
        let useCase = HandlePromotedNavigationUseCase(repository: repository)

        await #expect(throws: AliasedUrlsError.invalidPayload) {
            _ = try await useCase.handle(url: url)
        }
    }
}

@Suite("GetAliasedUrlsUseCase")
struct GetAliasedUrlsUseCaseTests {
    @Test func forwardsCatalogFromRepository() async throws {
        let dtos = [
            AliasedUrlDTO(alias: "preferences:notifications:activation",
                          pattern: "/preferences/notifications/activation"),
        ]
        let repository: any AliasedUrlsRepository = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { dtos })
        )
        let useCase = GetAliasedUrlsUseCase(repository: repository)

        let catalog = try await useCase.fetch()
        #expect(catalog.count == 1)
        #expect(catalog.first?.alias == .preferencesNotificationsActivation)
    }

    @Test func propagatesRepositoryError() async {
        let repository: any AliasedUrlsRepository = CachingAliasedUrlsRepository(
            dataSource: ClosureAliasedUrlsDataSource(catalogProvider: { () async throws(AliasedUrlsError) -> [AliasedUrlDTO] in
                throw AliasedUrlsError.pageNotReady
            })
        )
        let useCase = GetAliasedUrlsUseCase(repository: repository)

        await #expect(throws: AliasedUrlsError.pageNotReady) {
            _ = try await useCase.fetch()
        }
    }
}

// swiftformat:enable all
// swiftlint:enable all
