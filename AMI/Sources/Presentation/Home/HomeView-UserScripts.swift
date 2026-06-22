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
        case nativeValue = "NativeValue"
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
            UserScript(name: Script.nativeValue.rawValue,
                       script: WKUserScript(source: Self.nativeBridgeValueScript,
                                            injectionTime: .atDocumentStart,
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

    // This creates window.NativeBridge.nativeValue() that wraps the iOS messaging
    private static let nativeBridgeValueScript = """
    window.NativeValue = window.NativeValue || {};

    // - methodName : one of the listed method names
    // - params: {
    //     valueID: String,
    //     requestID: uuid
    //   }
    window.NativeValue.nativeValueRequest = function(methodName, params) {
        console.log('NativeBridge.nativeValueRequest called');
        window.webkit.messageHandlers.NativeValue.postMessage({
            method: methodName,
            params: params
        });
    };

    window.NativeValue.nativeValueResponse = function(requestID, valueAsString) {
        console.log(`nativeValueResponse(${requestID}, ${valueAsString})`);
    };

    console.log('NativeValue initialized');

    setTimeout(function() {
        console.log('timeout fired');
        window.NativeValue.nativeValueRequest('readPrivateInt', {
            valueID: 'ma_valeur',
            requestID: crypto.randomUUID()
        });
    }, 30);
    """
}

extension HomeUserScripts: WebViewUserScriptsProtocol {
    func userScriptEmittedMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        switch Script(rawValue: message.name) {
        case .consoleLog:
            printLog(message)
        case .nativeBridge:
            processMessage(message, for: viewModel)
        case .nativeValue:
            processNativeValueMessage(message, for: viewModel)
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

    func processNativeValueMessage(_ message: WKScriptMessage, for viewModel: SwiftUIWebView.ViewModel) {
        // Parse the message from JavaScript (format: {event: string, data: any})
        if let messageBody = message.body as? [String: Any],
           let methodName = messageBody["method"] as? String,
           let method = NativeValue.NativeValueMethodType(rawValue: methodName),
           let params = messageBody["params"] as? [String: String],
           let requestIDString = params["requestID"],
           let requestID = UUID(uuidString: requestIDString),
           let valueID = params["valueID"],
           let webView = viewModel.webView {
            AppLog.view.notice("\(AppLog.logHeader(self)) NativeValue request received: \(methodName) - \(String(describing: params))")

            Task {
                await callNativeValueAction(NativeValue.NativeValueRequestInput(ID: requestID, method: method, valueID: valueID),
                                            for: viewModel,
                                            webView: webView)
            }
        }
    }

    private func callNativeValueAction(_ params: NativeValue.NativeValueRequestInput,
                                       for viewModel: SwiftUIWebView.ViewModel,
                                       webView: WKWebView) async {
        switch params.method {
        case .readPrivateInt:
            Task {
                await callNativeActionResponse(value: "42", requestID: params.ID, webView: webView)
            }

        default:
            break
        }
    }

    @MainActor // `evaluateJavaScript` must be used from main thread only.
    private func callNativeActionResponse(value: String, requestID: UUID, webView: WKWebView) async {
        // Prepare javaScript script.
        let script = "window.NativeValue.nativeValueResponse('\(requestID)', '\(value)');"

        do {
            // Execute javaScript script
            _ = try await webView.evaluateJavaScript(script)
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) success")
        } catch {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) failed")
        }
    }
}
