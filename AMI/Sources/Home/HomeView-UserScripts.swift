//
//  HomeView-UserScripts.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

class HomeUserScripts {
    var scripts: [UserScript]

    // Enumerate existing scripts
    enum Script: String {
        case nativeBridge
        case consoleLog
    }

    // Enumerate existing events
    enum Event: String {
        case userLoggedIn = "user_logged_in"
        case notificationPermissionRequested = "notification_permission_requested"
        case notificationPermissionRemoved = "notification_permission_removed"
    }

    required init() {
        scripts = [
            UserScript(name: Script.nativeBridge.rawValue,
                       script: WKUserScript(source: Self.nativeBridgeScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)),
            UserScript(name: Script.consoleLog.rawValue,
                       script: WKUserScript(source: Self.consoleLogScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)),
        ]
    }

    // This creates window.NativeBridge.onEvent() that wraps the iOS messaging
    private static let nativeBridgeScript = """
    window.NativeBridge = {
        onEvent: function(eventName, data) {
            window.webkit.messageHandlers.NativeBridge.postMessage({
                event: eventName,
                data: data
            });
        }
    };
    console.log('NativeBridge initialized');
    """

    // JavaScript to capture console logs
    private static let consoleLogScript = """
    (function() {
        function sendLog(level, args) {
            var message = Array.prototype.slice.call(args).map(function(arg) {
                if (typeof arg === 'object') {
                    try {
                        return JSON.stringify(arg);
                    } catch (e) {
                        return String(arg);
                    }
                }
                return String(arg);
            }).join(' ');
            //
            window.webkit.messageHandlers.consoleLog.postMessage({
                level: level,
                message: message
            });
        }
        //
        var originalLog = console.log;
        var originalWarn = console.warn;
        var originalError = console.error;
        var originalInfo = console.info;
        var originalDebug = console.debug;
        //
        console.log = function() {
            sendLog('log', arguments);
            originalLog.apply(console, arguments);
        };
        //
        console.warn = function() {
            sendLog('warn', arguments);
            originalWarn.apply(console, arguments);
        };
        //
        console.error = function() {
            sendLog('error', arguments);
            originalError.apply(console, arguments);
        };
        //
        console.info = function() {
            sendLog('info', arguments);
            originalInfo.apply(console, arguments);
        };
        //
        console.debug = function() {
            sendLog('debug', arguments);
            originalDebug.apply(console, arguments);
        };
    })();
    """
}

extension HomeUserScripts: WebViewUserScripts {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .consoleLog:
            printLog(message)
        case .nativeBridge:
            processMessage(message)
        case .none:
            // Ignore unknown script message names
            break
        }
    }

    func printLog(_ message: WKScriptMessage) {
        guard message.name == Script.consoleLog.rawValue,
              let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let logMessage = body["message"] as? String else { return }

        let prefix = "[WebView Console]"
        switch level {
        case "error":
            print("\(prefix) ❌ ERROR: \(logMessage)")
        case "warn":
            print("\(prefix) ⚠️ WARN: \(logMessage)")
        case "info":
            print("\(prefix) ℹ️ INFO: \(logMessage)")
        case "debug":
            print("\(prefix) 🔍 DEBUG: \(logMessage)")
        default:
            print("\(prefix) 📝 LOG: \(logMessage)")
        }
    }

    func processMessage(_ message: WKScriptMessage) { // }, coordinator: WebViewOldCoordinator) {
        // Parse the message from JavaScript (format: {event: string, data: any})
        if let messageBody = message.body as? [String: Any],
           let eventName = messageBody["event"] as? String {
            let data = messageBody["data"]
            print("WebView: Event received: \(eventName) - \(String(describing: data))")

            switch Event(rawValue: eventName) {
            case .userLoggedIn:
//                coordinator.isUserLoggedIn = true
                // Trigger device registration when user logs in
//                coordinator.triggerDeviceRegistration()
                break
            case .notificationPermissionRequested:
                NotificationHelper.requestPermission()
            case .notificationPermissionRemoved:
                NotificationHelper.openSettings()
                WebViewOldManager.shared.goHome()
            default:
                break
            }
        }
    }
}
