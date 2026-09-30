//
//  ServiceView-PostMessageScripts.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

class ServiceViewPostMessageScripts {
    // Enumerate existing scripts
    enum Script: String {
        case postMessage
    }

    var scripts: [UserScript]
    weak var context: NSObject?

    required init(context: NSObject?) {
        scripts = [
            UserScript(name: Script.postMessage.rawValue,
                       script: WKUserScript(source: Self.postMessageScript,
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: false)),
        ]
        self.context = context
    }

    // JavaScript to capture console logs
    private static let postMessageScript = """
    (function() {
        window.ApplicationAmi = window.ApplicationAmi || {};
        window.ApplicationAmi.servicePostMessage = function(body) {
            window.webkit.messageHandlers.postMessage.postMessage(body);
        };
    })();
    console.log('ApplicationAmi.servicePostMessage initialized');
    """
}

extension ServiceViewPostMessageScripts: WebViewUserScriptsProtocol {
    func userScriptEmittedMessage(_ message: WKScriptMessage) {
        switch Script(rawValue: message.name) {
        case .postMessage:
            handlePostMessage(message)
        case .none:
            // Ignore unknown script message names
            break
        }
    }

    private func handlePostMessage(_ message: WKScriptMessage) {
        guard message.name == Script.postMessage.rawValue,
              // The received data is not direct JSON. It is a String representing a JSON value.
              let payloadAsString = message.body as? String,
              // Convert the string to raw Data
              let payloadAsData = payloadAsString.data(using: .utf8) else {
            AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unable to decode received value")
            return
        }

        Task {
            await (context as? ServiceView.ViewModel)?.receivePSLFinalPayload(payload: payloadAsData)
        }
    }
}
