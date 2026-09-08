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
    typealias DownloadStartedAction = (Result<String, Error>) -> Void // String parameter is suggested filename.
    typealias DownloadCompleteAction = (Result<URL, Error>) -> Void

    var onDownloadStarted: DownloadStartedAction?
    var onDownloadComplete: DownloadCompleteAction?

    // Association table to keep trace of running downloads.
    private var destinations: [ObjectIdentifier: URL] = [:]

    /// List file extensions that represents resource to download rather than display in web view.
    static func destinationUrlIsDownloadableFile(_ destinationUrl: URL?) -> Bool {
        guard let destinationUrl else {
            return false
        }

        let downloadableFileExtensions = ["pdf"]

        return downloadableFileExtensions.contains(destinationUrl.pathExtension)
    }

    /// Mehtod to be called when controller doesn't need the downloaded file anymore.
    func cleanup(downloadedUrl: URL) {
        // Remove downloaded folder (there is only one unique folder by downloaded file).
        deleteTemporaryDownload(at: downloadedUrl.deletingLastPathComponent())
    }

    private func createTemporaryDestinationFolder() throws -> URL {
        // Create a default unique destination temporary folder.
        let destinationFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, conformingTo: .folder)
        try FileManager.default.createDirectory(at: destinationFolder, withIntermediateDirectories: true)
        return destinationFolder
    }

    private func deleteTemporaryDownload(at destinationUrl: URL) {
        try? FileManager.default.removeItem(at: destinationUrl)
    }
}

extension WebViewDownloadCoordinator: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        do {
            // Add suggested filename to destination download path.
            let localDestinationUrl = try createTemporaryDestinationFolder().appendingPathComponent(suggestedFilename)

            // Store destination url associated with WKDownload object for cleanup on success.
            destinations[ObjectIdentifier(download)] = localDestinationUrl

            // Inform controller that download stared.
            onDownloadStarted?(.success(suggestedFilename))

            return localDestinationUrl
        } catch {
            // Inform controller that download can't start.
            onDownloadStarted?(.failure(error))

            return nil
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        // Remove Download tracking as it succeed.
        guard let url = destinations.removeValue(forKey: ObjectIdentifier(download)) else {
            return
        }

        onDownloadComplete?(.success(url))
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        // Remove Download tracking as it succeed.
        if let url = destinations.removeValue(forKey: ObjectIdentifier(download)) {
            // Remove destination folder if download failed.
            cleanup(downloadedUrl: url)
        }

        onDownloadComplete?(.failure(error))
    }
}
