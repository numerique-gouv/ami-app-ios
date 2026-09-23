//
//  WebViewLocalStorageManager.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 15/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct WebViewLocalStorageManager {
    private weak var webView: WKWebView?

    init(webView: WKWebView) {
        self.webView = webView
    }

    @MainActor // `evaluateJavaScript` must be used from main thread only.
    func readInLocalStorage(key: String) async -> Any? {
        guard let webView else {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage not called because no webView initialzed")
            return nil
        }

        // Prepare javaScript script.
        let script = "localStorage.getItem('\(key)');"

        do {
            // Execute javaScript script
            let value = try await webView.evaluateJavaScript(script)
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage success - `\(key)` -> `\(value.debugDescription, privacy: .private)`")
            return value
        } catch {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage failed to read key `\(key)`: \(error)")
            return nil
        }
    }

    @MainActor // `evaluateJavaScript` must be used from main thread only.
    func writeInLocalStorage(key: String, value: String) async {
        guard let webView else {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage not called because no webView initialzed")
            return
        }

        // Prepare javaScript script.
        let script = "localStorage.setItem('\(key)', '\(value)');"

        do {
            // Execute javaScript script
            _ = try await webView.evaluateJavaScript(script)
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage success - `\(key)` = `\(value, privacy: .private)`")
        } catch {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage failed to set key `\(key)` to value `\(value, privacy: .private)`: \(error)")
        }
    }

    /// Delete all local data and cookies associated with the current web session.
    @MainActor
    func deleteSessionLocalData() async {
        // Check if website data store store exists.
        guard let websiteDataStore = webView?.configuration.websiteDataStore else {
            return
        }

        // List data types to clear, excluding cookies that will be treated separately (a special cookie need to be preserved).
        var dataTypesToClear = WKWebsiteDataStore.allWebsiteDataTypes()
        dataTypesToClear.remove(WKWebsiteDataTypeCookies)
        let records = await websiteDataStore.dataRecords(ofTypes: dataTypesToClear)
        for record in records {
            await websiteDataStore.removeData(ofTypes: record.dataTypes, for: [record])
        }

        // Delete cookies except FranceConnect special cookie.
        await deleteCookiesExceptFranceConnectTrustedDevice()
    }

    /// Delete all local cookies except a FranceConnect cookie named `trustedDevice`.
    @MainActor
    private func deleteCookiesExceptFranceConnectTrustedDevice() async {
        // Check if website data store store exists.
        guard let websiteDataStore = webView?.configuration.websiteDataStore else {
            return
        }

        // Get cookies store.
        let cookieStore = websiteDataStore.httpCookieStore

        // Grab cookie to preserve.
        let protectedCookie = await cookieStore.allCookies().first {
            $0.name == "trustedDevice" && $0.domain == Secrets.franceconnectTrustedDeviceCookieDomain
        }

        // Delete all cookies.
        await websiteDataStore.removeData(ofTypes: [WKWebsiteDataTypeCookies], modifiedSince: .distantPast)

        // Restore cookie to preserve if it exists.
        if let protectedCookie {
            await cookieStore.setCookie(protectedCookie)
        }
    }

    #if IS_AMI_STAGING
        /// Delete FranceConnect cookie named `fc_session_id` to simulate FranceConnect session expiration.
        @MainActor
        func expireFranceConnectSession() async {
            // Check if website data store store exists.
            guard let websiteDataStore = webView?.configuration.websiteDataStore else {
                return
            }

            // Get cookies store.
            let cookieStore = websiteDataStore.httpCookieStore

            // Add dot prefix to OIDC domains
            let oidcDomainsDotPrefixed = Secrets.oidcDomainsStrings.map { "." + $0 }

            // Grab cookie to delete and delete it if it is found.
            if let cookieToDelete = await cookieStore.allCookies().first(where: {
                $0.name == "fc_session_id" && oidcDomainsDotPrefixed.contains($0.domain)
            }) {
                await cookieStore.deleteCookie(cookieToDelete)
                AppLog.view.notice("\(AppLog.logHeader(self)) FranceConnect 'fc_session_id' cookie deleted.")
            }
        }
    #endif
}
