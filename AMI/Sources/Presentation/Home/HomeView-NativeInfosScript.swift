//
//  HomeView-NativeInfosScript.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

class HomeNativeInfosScripts {
    // Enumerate existing scripts
    enum Script: String {
        case getNativeInfos
    }

    var scripts: [UserScript]

    @MainActor
    required init() async {
        let deviceID = await DeviceID.getOrCreateDeviceID()

        scripts = [
            UserScript(name: Script.getNativeInfos.rawValue,
                       script: WKUserScript(source: Self.getNativeInfosScript(deviceID: deviceID),
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: true)),
        ]
    }

    #if IS_AMI_PRODUCTION
        // Hide `environment` value in Production environment.
        private static let environement = ""
    #elseif IS_AMI_PREPRODUCTION
        private static let environement = "preproduction"
    #elseif IS_AMI_STAGING
        private static let environement = "staging"
    #else
        private static let environement = "unknown"
    #endif

    // This creates window.NativeBridge.getNativeVersion() HS function.
    private static func getNativeInfosScript(deviceID: DeviceID.DeviceIdType) -> String {
        // Private structure containing strucutured data passed to web page.
        struct NativeInfos: Encodable {
            let platform: String
            let version: String
            let device_id: String
            let promoted_url_aliases: [String]
        }

        let environmentPrefix = if environement.count > 0 { " " } else { "" }

        // The data structure filled with actual values.
        let infos = NativeInfos(
            platform: "ios",
            // Concatenate version informations in a single string for display in web application.
            version: "ios \(AppBundle.version) (\(AppBundle.build))\(environmentPrefix)\(environement)",
            device_id: deviceID,
            promoted_url_aliases: PromotedAliases.allCases.map(\.rawValue)
        )

        // Encode string value for transfer.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        guard let jsonData = try? encoder.encode(infos) else {
            return ""
        }
        // Force non-optional else an optional description string will be interpolated
        // in the following JS script.
        let jsonString = String(bytes: jsonData, encoding: .utf8) ?? ""

        return """
        (function() {
            window.NativeInfos = window.NativeInfos || {};

            window.NativeInfos.getInfos = function() {
                return \(jsonString);
            };
        })();
        console.log('NativeInfos initialized');
        """
    }
}

// Encodable capability is only used here.
extension PromotedAliases: Encodable {}

extension HomeNativeInfosScripts: WebViewUserScripts {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .getNativeInfos, .none:
            // Ignore unknown script message names
            break
        }
    }
}
