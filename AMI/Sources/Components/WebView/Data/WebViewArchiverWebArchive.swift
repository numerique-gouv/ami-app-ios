//
//  WebViewArchiverWebArchive.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 22/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

/// The archive stores the HTML plus the subresources WebKit had already loaded, such as CSS and images
final class WebViewArchiverWebArchive: WebViewArchiver, Sendable {
    func archive(_ webView: WKWebView) async throws(WebViewArchiverError) {
        // Verify the loaded resource is qualified by a scheme.
        guard let urlScheme = webView.url?.scheme else {
            throw .unsupportedScheme(nil)
        }

        // Verify the loaded resource is an HTTP resource.
        guard ["https", "http"].contains(urlScheme.lowercased()) else {
            throw .unsupportedScheme(urlScheme)
        }

        // Get the archive Data on the main actor (required by WebKit)
        let data: Data
        do {
            data = try await withCheckedThrowingContinuation { continuation in
                webView.createWebArchiveData {
                    continuation.resume(with: $0)
                }
            }
        } catch {
            throw .unableToArchive(error)
        }

        // Write the archive Data off the main actor
        let writeUrl = Self.archiveUrl()
        do {
            try await Self.writeArchiveInBackground(data: data, archiveUrl: writeUrl)
        } catch {
            throw .unableToArchive(error)
        }
    }

    func restore(_ webView: WKWebView, baseURL: URL) async throws(WebViewArchiverError) {
        let readUrl = Self.archiveUrl()
        let data: Data
        do {
            // Get data off the main actor
            data = try await Self.readArchiveInBackground(archiveUrl: readUrl)
        } catch {
            throw .unableToRestore(error)
        }

        // Load data into webView on the main actor (required by WebKit)
        webView.load(data, mimeType: "application/x-webarchive", characterEncodingName: "utf-8", baseURL: baseURL)
    }

    private nonisolated static func archiveUrl() -> URL {
        let archiveFolder = "webArchives"
        let name = "amiWebApplication"
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(archiveFolder)
            .appendingPathComponent(name, conformingTo: .webArchive)
    }

    @concurrent
    private static func writeArchiveInBackground(data: Data, archiveUrl: URL) async throws {
        // Create the directory if necessary.
        try FileManager.default.createDirectory(at: archiveUrl.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try data.write(to: archiveUrl, options: .atomic)
    }

    @concurrent
    private static func readArchiveInBackground(archiveUrl: URL) async throws -> Data {
        try Data(contentsOf: archiveUrl)
    }
}
