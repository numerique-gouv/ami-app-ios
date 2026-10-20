//
//  WebViewNavigationStateDelegate.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 19/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

nonisolated protocol WebViewNavigationStateDelegate: AnyObject {
    func navigationWillStart(navigationAction: WKNavigationAction)

    func navigationDidStart()

    func navigationDidFinish()

    func navigationDidFailed(withError error: Error)
}
