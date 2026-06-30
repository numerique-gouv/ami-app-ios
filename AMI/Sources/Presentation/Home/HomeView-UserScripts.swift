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
        case getNativeInfos
    }

    // Enumerate existing events
    enum Event: String {
        case userLoggedIn = "user_logged_in"
        case userLoggedOut = "user_logged_out"
        case notificationPermissionRequested = "notification_permission_requested"
        case notificationPermissionRemoved = "notification_permission_removed"
    }

    typealias UserLoggedInAction = () -> Void
    typealias UserLoggedOutAction = () -> Void

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
            UserScript(name: Script.getNativeInfos.rawValue,
                       script: WKUserScript(source: Self.getNativeInfosScript,
                                            injectionTime: .atDocumentStart,
                                            forMainFrameOnly: true)),
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
    private static let getNativeInfosScript = """
        (function() {
            window.NativeInfos = window.NativeInfos || {};

            window.NativeInfos.getInfos = function() {
                return {
                        plateform: "ios",
                        app_name: "\(AppBundle.name)",
                        version: "\(AppBundle.version)",
                        build: \(AppBundle.build),
                        environment: "\(environement)",
                        mode: "\(mode)"
                       };
            };
        })();
        console.log('NativeInfos initialized');
    """
}

extension HomeUserScripts: WebViewUserScriptsProtocol {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .consoleLog:
            printLog(message)
        case .nativeBridge:
            processMessage(message, for: viewModel)
        case .getNativeInfos, .none:
            // Ignore unknown script message names
            break
        }
    }

    func printLog(_ message: WKScriptMessage) {
        guard message.name == Script.consoleLog.rawValue,
              let body = message.body as? [String: Any],
              let level = body["level"] as? String,
              let logMessage = body["message"] as? String else { return }

        switch level {
        case "error":
            AppLog.view.error("\(AppLog.logHeader(self)) ❌ ERROR: \(logMessage)")
        case "warn":
            AppLog.view.warning("\(AppLog.logHeader(self)) ⚠️ WARN: \(logMessage)")
        case "info":
            AppLog.view.info("\(AppLog.logHeader(self)) ℹ️ INFO: \(logMessage)")
        case "debug":
            AppLog.view.debug("\(AppLog.logHeader(self)) 🔍 DEBUG: \(logMessage)")
        default:
            AppLog.view.notice("\(AppLog.logHeader(self)) 📝 LOG: \(logMessage)")
        }
    }

    func processMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        // Parse the message from JavaScript (format: {event: string, data: any})
        if let messageBody = message.body as? [String: Any],
           let eventName = messageBody["event"] as? String {
            let data = messageBody["data"]
            AppLog.view.notice("\(AppLog.logHeader(self)) Event received: \(eventName) - \(String(describing: data))")

            switch Event(rawValue: eventName) {
            case .userLoggedIn:
                userLoggedInAction?()
            case .userLoggedOut:
                userLoggedOutAction?()
            case .notificationPermissionRequested:
                NotificationStatus.requestPermission()
            case .notificationPermissionRemoved:
                NotificationStatus.openSettings()
            default:
                break
            }
        }
    }
}
