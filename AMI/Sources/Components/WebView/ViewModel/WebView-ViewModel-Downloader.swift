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
        // Create default unique destination temporary folder.
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Add suggested filename to destination download path.
        let url = dir.appendingPathComponent(suggestedFilename)

        // Store destination url associated with WKDownload object for cleanup on success.
        destinations[ObjectIdentifier(download)] = url

        return url
    }

    func downloadDidFinish(_ download: WKDownload) {
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
}
