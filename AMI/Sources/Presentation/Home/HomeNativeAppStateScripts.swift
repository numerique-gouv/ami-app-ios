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
        let pushNotificationEnabled = await NotificationStatus.isEnabled()

        scripts = [
            UserScript(name: Script.getNativeAppState.rawValue,
                       script: WKUserScript(source: Self.getNativeAppStateScript(pushNotificationEnabled: pushNotificationEnabled),
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: true)),
        ]
    }

    /// Builds the javascript call to update `pushNotificationEnabled` variable with new value.
    static func javascriptToUpdatePushNotificationEnabled(_ enabled: Bool) -> String {
        "window.NativeAppState?.setPushNotificationEnabled(\(enabled))"
    }

    // This creates window.NativeAppState.isPushNotificationEnabled() function.
    private static func getNativeAppStateScript(pushNotificationEnabled: Bool) -> String {
        """
        (function() {
            window.NativeAppState = window.NativeAppState || {};

            let pushNotificationEnabled = \(pushNotificationEnabled);

            window.NativeAppState.isPushNotificationEnabled = function() {
                return pushNotificationEnabled;
            };
            window.NativeAppState.setPushNotificationEnabled = function(v) {
                pushNotificationEnabled = Boolean(v);
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
