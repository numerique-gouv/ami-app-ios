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
        private static let environement = "production"
    #elseif IS_AMI_STAGING
        private static let environement = "staging"
    #else
        private static let environement = "unknown"
    #endif

    #if DEBUG
        private static let mode = "debug"
    #else
        private static let mode = "release"
    #endif

    // This creates window.NativeBridge.getNativeVersion() HS function.
    private static func getNativeInfosScript(deviceID: DeviceID.DeviceIdType) -> String { """
    (function() {
        window.NativeInfos = window.NativeInfos || {};

        window.NativeInfos.getInfos = function() {
            return {
                    plateform: "ios",
                    app_name: "\(AppBundle.name)",
                    version: "\(AppBundle.version)",
                    build: \(AppBundle.build),
                    environment: "\(environement)",
                    mode: "\(mode)",
                    device_id: "\(deviceID)"
                   };
        };
    })();
    console.log('NativeInfos initialized');
    """
    }
}

extension HomeNativeInfosScripts: WebViewUserScriptsProtocol {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .getNativeInfos, .none:
            // Ignore unknown script message names
            break
        }
    }
}
