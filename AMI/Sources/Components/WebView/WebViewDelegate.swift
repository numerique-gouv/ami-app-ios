//
//  WebViewDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 19/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

protocol WebViewDelegate: AnyObject {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool

    func navigationWillStart(navigationAction: WKNavigationAction)

    func navigationDidStart()

    func navigationDidFinish()

    func navigationDidFailed(withError error: Error)
}

extension WebViewDelegate {
    // These default empty implementation makes the above methods optional to implement.
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool { true }
    func navigationWillStart(navigationAction: WKNavigationAction) {}
    func navigationDidStart() {}
    func navigationDidFinish() {}
    func navigationDidFailed(withError error: Error) {}
}

class WebViewDelegateSimulatorImplementation: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        print("[WebViewDelegate] Check if navigation is allowed to \(navigationAction.request.url?.absoluteString ?? "<no destination URL found>")")
        return true
    }

    func navigationWillStart() {
        AppLog.view.notice("\(AppLog.logHeader(caller: self, function: #function)) Navigation will start")
    }

    func navigationDidStart() {
        AppLog.view.notice("\(AppLog.logHeader(caller: self, function: #function)) Navigation did start")
    }

    func navigationDidFinish() {
        AppLog.view.notice("\(AppLog.logHeader(caller: self, function: #function)) Navigation did finish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.view.notice("\(AppLog.logHeader(caller: self, function: #function)) Navigation did failed with error: \(error)")
    }
}
