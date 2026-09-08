//
//  WebView-ViewModel-Downloader.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 07/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

final class WebViewDownloadCoordinator: NSObject {
    typealias CompletionType = (Result<URL, Error>) -> Void

    private var destinations: [ObjectIdentifier: URL] = [:]

    var onCompletion: CompletionType?
}

extension WebViewDownloadCoordinator: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        do {
            // Add suggested filename to destination download path.
            let localDestinationUrl = try createTemporaryDestinationFolder().appendingPathComponent(suggestedFilename)

            // Store destination url associated with WKDownload object for cleanup on success.
            destinations[ObjectIdentifier(download)] = localDestinationUrl

            // TODO: Display information about started download.

            return localDestinationUrl
        } catch {
            // TODO: Display information about error download.

            return nil
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        // Remove Download tracking as it succeed.
        guard let url = destinations.removeValue(forKey: ObjectIdentifier(download)) else {
            return
        }

        onCompletion?(.success(url))
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        if let url = destinations.removeValue(forKey: ObjectIdentifier(download)) {
            // Remove destination folder if download failed.
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }

        onCompletion?(.failure(error))
    }

    private func createTemporaryDestinationFolder() throws -> URL {
        // Create a default unique destination temporary folder.
        let destinationFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .folder)
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        return destinationFolder
    }

    func deleteTemporaryDownload(at destinationUrl: URL) {
        try? FileManager.default.removeItem(at: destinationUrl)
    }
}
