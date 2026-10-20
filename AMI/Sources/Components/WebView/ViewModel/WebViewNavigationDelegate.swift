//
//  WebViewNavigationDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 19/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

protocol WebViewNavigationDelegate: AnyObject {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) async -> Bool

    func navigationWillStart(navigationAction: WKNavigationAction)

    func navigationDidStart()

    func navigationDidFinish()

    func navigationDidFailed(withError error: Error)
}

// extension WebViewNavigationDelegate {
//     // These default empty implementation makes the above methods optional to implement.
//     func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) async -> Bool { true }
//     func navigationWillStart(navigationAction: WKNavigationAction) {}
//     func navigationDidStart() {}
//     func navigationDidFinish() {}
//     func navigationDidFailed(withError error: Error) {}
// }
