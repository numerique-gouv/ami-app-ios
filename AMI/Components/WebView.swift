//
//  WebView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
import Foundation
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    init(_ url: URL) {
        self.url = url
    }
    
    func makeUIView(context: Context) -> some UIView {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // JavaScript to capture console logs
        let consoleLogScript = """
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

                window.webkit.messageHandlers.consoleLog.postMessage({
                    level: level,
                    message: message
                });
            }

            var originalLog = console.log;
            var originalWarn = console.warn;
            var originalError = console.error;
            var originalInfo = console.info;
            var originalDebug = console.debug;

            console.log = function() {
                sendLog('log', arguments);
                originalLog.apply(console, arguments);
            };

            console.warn = function() {
                sendLog('warn', arguments);
                originalWarn.apply(console, arguments);
            };

            console.error = function() {
                sendLog('error', arguments);
                originalError.apply(console, arguments);
            };

            console.info = function() {
                sendLog('info', arguments);
                originalInfo.apply(console, arguments);
            };

            console.debug = function() {
                sendLog('debug', arguments);
                originalDebug.apply(console, arguments);
            };
        })();
        """

        let userScript = WKUserScript(source: consoleLogScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(userScript)
        contentController.add(context.coordinator, name: "consoleLog")

        configuration.userContentController = contentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = webView
        webView.load(URLRequest(url: url))
        return webView

    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }

    func makeCoordinator() -> WebViewCoordinator {
        WebViewCoordinator()
    }
}
