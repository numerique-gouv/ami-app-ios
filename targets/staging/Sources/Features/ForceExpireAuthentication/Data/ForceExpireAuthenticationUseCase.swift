//
//  ForceExpireAuthenticationUseCase.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 13/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct ForceExpireAuthenticationUseCase: Sendable {
    private let cookiesStore: WKHTTPCookieStore
    private let oidcDomainsStringsList: [String]

    init(cookiesStore: WKHTTPCookieStore, oidcDomainsStringsList: [String]) {
        self.cookiesStore = cookiesStore
        // List OIDC domains with and without '.' prefix.
        self.oidcDomainsStringsList = oidcDomainsStringsList.flatMap { [$0, "." + $0] }
    }

    @MainActor // WKHTTPCookieStore is main actor isolated.
    func execute() async {
        // List all existing cookies owned by a listed OIDC domain.
        let cookiesToDelete = await cookiesStore.allCookies().filter { cookie in
            !oidcDomainsStringsList.filter { $0.hasSuffix(cookie.domain) }.isEmpty
        }

        // Delete all OIDC cookies.
        for cookie in cookiesToDelete {
            await cookiesStore.deleteCookie(cookie)
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) cookie named \"\(cookie.name)\" for domain \"\(cookie.domain)\" deleted.")
        }
    }
}
