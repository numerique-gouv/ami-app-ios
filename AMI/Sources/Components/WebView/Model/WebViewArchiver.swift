//
//  WebViewArchiver.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 22/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

/// Implementations choose their own isolation: main-actor-isolated
/// conformers are permitted (required when touching `WKWebView` directly)
/// as well as background-friendly ones. Nonisolated `async` witnesses
/// run on the caller's executor — conformers are responsible for their
/// own actor hopping if they need off-main work.
///
/// Conformers that hold mutable state (archive indexes, caches,
/// bookkeeping) should be isolated — typically implemented as an actor —
/// so that `archive` and `restore` are serialized and never observe a
/// half-written snapshot. Stateless conformers (storage path fully
/// determined by the input) can be plain `Sendable` structs.
@MainActor
protocol WebViewArchiver: Sendable {
    func archive(_ webView: WKWebView) async throws(WebViewArchiverError)
    func restore(_ webView: WKWebView, baseURL: URL) async throws(WebViewArchiverError)
}
