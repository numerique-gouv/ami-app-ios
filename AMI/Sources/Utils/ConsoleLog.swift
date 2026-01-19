import Foundation
import WebKit

enum ConsoleLog {
    static func attach(_ contentController: WKUserContentController, _ handler: WKScriptMessageHandler) {
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
        contentController.add(handler, name: "consoleLog")
    }

    static func printLog(_ message: WKScriptMessage) {
        guard message.name == "consoleLog",
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
}
