//
//  WebViewUserScriptsProtocol.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

struct UserScript {
    let name: String
    let script: WKUserScript
}

protocol WebViewUserScriptsProtocol {
    var scripts: [UserScript] { get }

    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel)
}
