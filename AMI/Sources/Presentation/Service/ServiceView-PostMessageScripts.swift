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
              let bodyString = message.body as? String,
              // Convert the string to raw Data
              let bodyData = bodyString.data(using: .utf8),
              // Try to decode the raw Data to a [String: String] structure.
              let bodyJson = try? JSONDecoder().decode([String: String].self, from: bodyData) else {
            AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unable to decode received value")
            return
        }

        let pdfJsonKey = "recapPDF"

        if let pdfContent = bodyJson[pdfJsonKey],
           let pdfData = Data(base64Encoded: pdfContent) {
            let url = URL.documentsDirectory.appending(path: "test_pdf.pdf")

            do {
                try pdfData.write(to: url, options: [.atomic, .noFileProtection])
                AppLog.viewModel.debug("\(AppLog.logHeader(self)) PDF file written at: \(url)")
            } catch {
                AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unable to write PDF file: \(error.localizedDescription)")
            }
        }

        // Try to present received data to user.
        if let jsonData = try? JSONSerialization.data(withJSONObject: bodyJson, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            (context as? ServiceView.ViewModel)?.receivedContent = InfoPanelContent(text: jsonString)
        }
    }
}
