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
    private var destinations: [ObjectIdentifier: URL] = [:]

    var onFinish: ((URL) -> Void)?
    var onFailure: ((Error) -> Void)?
}

extension WebViewDownloadCoordinator: WKDownloadDelegate {
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String) async -> URL? {
        let dir = FileManager.default.temporaryDirectory .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(suggestedFilename)
        destinations[ObjectIdentifier(download)] = url
        return url
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let url = destinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
        onFinish?(url)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        if let url = destinations.removeValue(forKey: ObjectIdentifier(download)) {
            try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
        }
        onFailure?(error)
    }
}
