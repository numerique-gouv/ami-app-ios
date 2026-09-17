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

    function testPostMessage() {
        const jsonContent = {
            encoding_mode: "base64",
            signing_key: "<SIGNING KEY>",
            process_id: "p_24554",
            process_type: "OperationTranquilliteVacances",
            partner_id: "psl",
            initiating_service: "gendarmerie",
            start_date: "2026-09-01",
            end_date: "2026-09-23",
            pdf: null,
            initiating_service_contact_name: "John Doe",
            initiating_service_contact_phone: "+33607080910",
            initiating_service_contact_address: "1 place de l'Étoile - Paris",
            fc_hash: "<FC HASH>"
        };

        window.ApplicationAmi.servicePostMessage(jsonContent);
    }

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
              let body = message.body as? [String: Any] else {
            return
        }

        print("postMessage received. Body ->\n\(body)")

        if let jsonData = try? JSONSerialization.data(withJSONObject: body, options: [.prettyPrinted]),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            (context as? HomeView.ViewModel)?.receivedContent = InfoPanelContent(text: jsonString)
        }
    }
}
