//
//  HomeViewNavigationState.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 22/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

/// DefaultWebViewNavigationState only log navigation events.
/// No logic is processed on any navigation event.
@MainActor
final class HomeViewNavigationState: WebViewNavigationState {
    let baseUrl: URL
    weak var webView: WKWebView?

    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }

    func navigationWillStart(navigationAction: WKNavigationAction) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation will start")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did start")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did finish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did failed with error: \(error)")
    }
}
