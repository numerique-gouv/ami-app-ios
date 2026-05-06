//
//  HomeView-UserScripts.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import SwiftUI
import WebKit

class HomeUserScripts {
    // Enumerate existing scripts
    enum Script: String {
        case nativeBridge = "NativeBridge"
        case consoleLog
        case nativeURLs
    }

    // Enumerate existing events
    enum Event: String {
        case userLoggedIn = "user_logged_in"
        case userLoggedOut = "user_logged_out"
        case notificationPermissionRequested = "notification_permission_requested"
        case notificationPermissionRemoved = "notification_permission_removed"
        case navigateTo
    }

    typealias UserLoggedInAction = () -> Void
    typealias UserLoggedOutAction = () -> Void
    var onNavigate: ((Any?) -> Void)?

    var scripts: [UserScript]
    var userLoggedInAction: UserLoggedInAction?
    var userLoggedOutAction: UserLoggedOutAction?

    required init() {
        scripts = [
            UserScript(name: Script.nativeBridge.rawValue,
                       script: WKUserScript(source: Self.nativeBridgeScript,
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: false)),
            UserScript(name: Script.consoleLog.rawValue,
                       script: WKUserScript(source: Self.consoleLogScript,
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: false)),
            UserScript(name: Script.nativeURLs.rawValue,
                       script: WKUserScript(source: Self.nativeURLsScript,
                                            injectionTime: .atDocumentEnd,
                                            forMainFrameOnly: false)),
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

    // This sets window.NativeURLs so the web frontend knows which URLs are handled natively
    private static let nativeURLsScript: String = {
        let urls = Array(nativeRoutes.keys)
        let data = (try? JSONSerialization.data(withJSONObject: urls)) ?? Data("[]".utf8)
        let json = String(data: data, encoding: .utf8)! // safe: JSONSerialization always produces valid UTF-8
        return "window.NativeURLs = \(json);"
    }()

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

extension HomeUserScripts: WebViewUserScriptsProtocol {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .consoleLog:
            printLog(message)
        case .nativeBridge:
            processMessage(message, for: viewModel)
        case .nativeURLs, .none:
            break
        }
    }

    func printLog(_ message: WKScriptMessage) {
        guard message.name == Script.consoleLog.rawValue,
              let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let logMessage = body["message"] as? String else { return }

        let prefix = "[HomeUserScripts Console]"
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

    func processMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        // Parse the message from JavaScript (format: {event: string, data: any})
        if let messageBody = message.body as? [String: Any],
           let eventName = messageBody["event"] as? String {
            let data = messageBody["data"]
            print("[HomeUserScripts]: Event received: \(eventName) - \(String(describing: data))")

            switch Event(rawValue: eventName) {
            case .userLoggedIn:
                userLoggedInAction?()
            case .userLoggedOut:
                userLoggedOutAction?()
            case .notificationPermissionRequested:
                NotificationStatus.requestPermission()
            case .notificationPermissionRemoved:
                NotificationStatus.openSettings()
            case .navigateTo:
                onNavigate?(data)
            default:
                break
            }
        }
    }
}
