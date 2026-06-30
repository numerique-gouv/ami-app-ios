//
//  WeakScriptMessageHandler.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 23/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

// from: https://stackoverflow.com/a/26383032/399439

// A lightweight trampoline that prevents WKUserContentController
// from strongly retaining SwiftUIWebView.ViewModel.
final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
