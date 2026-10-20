//
//  WebViewNavigationDelegateSimulator.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
class WebViewNavigationDelegateSimulator: @MainActor WebViewNavigationDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) async -> Bool {
        let destination = navigationAction.request.url?.absoluteString ?? "<no destination URL found>"
        AppLog.view.notice("\(AppLog.logHeader(self)) Check if navigation is allowed to \(destination)")
        return true
    }

    func navigationWillStart(navigationAction: WKNavigationAction) {
        AppLog.view.notice("\(AppLog.logHeader(self)) Navigation will start")
    }

    func navigationDidStart() {
        AppLog.view.notice("\(AppLog.logHeader(self)) Navigation did start")
    }

    func navigationDidFinish() {
        AppLog.view.notice("\(AppLog.logHeader(self)) Navigation did finish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.view.notice("\(AppLog.logHeader(self)) Navigation did failed with error: \(error)")
    }
}
