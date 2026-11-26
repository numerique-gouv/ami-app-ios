//
//  HomeNativeAppStateScripts.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 26/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

class HomeNativeAppStateScripts {
    // Enumerate existing scripts
    enum Script: String {
        case getNativeAppState
    }

    var scripts: [UserScript]

    @MainActor
    required init() async {
        let notificationsActivationState = await NotificationStatus.authorizationStatus()

        scripts = [
            UserScript(name: Script.getNativeAppState.rawValue,
                       script: WKUserScript(source: Self.getNativeAppStateScript(pushNotificationEnabled: notificationsActivationState == .authorized),
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: true)),
        ]
    }

    // This creates window.NativeAppState.isPushNotificationEnabled() function.
    private static func getNativeAppStateScript(pushNotificationEnabled: Bool) -> String {
        """
        (function() {
            window.NativeAppState = window.NativeAppState || {};

            window.NativeAppState.isPushNotificationEnabled = function() {
                return \(pushNotificationEnabled);
            };
        })();
        console.log('NativeAppState initialized');
        """
    }
}

extension HomeNativeAppStateScripts: WebViewUserScripts {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .getNativeAppState, .none:
            // Ignore unknown script message names
            break
        }
    }
}
