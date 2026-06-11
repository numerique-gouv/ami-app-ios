//
//  WebView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension SwiftUIWebView {
    // Configguration that can be shared by all SwiftUIWebView to access the same cookie store.
    static let sharedConfiguration = {
        let configuration = WKWebViewConfiguration()
        // Here, we can customize webView configuration. especially on `webSiteDataStore`.
        return configuration
    }()

    @Observable
    class ViewModel: NSObject {
        typealias UrlChangeAction = @Sendable (SwiftUIWebView.ViewModel, URL?) -> Void

        weak var webView: WKWebView? {
            didSet {
                configure()
            }
        }

        var urlChangeAction: UrlChangeAction? {
            didSet {
                configure()
            }
        }

        let configuration: WKWebViewConfiguration
        let rootUrl: URL
        var delegate: WebViewDelegate?
        let userScripts: WebViewUserScriptsProtocol?
        let allowsBackForwardNavigationGestures: Bool
        #if DEBUG
            var acceptSelfSignedCertificate = false
        #endif

        private(set) var isLoading = false
        private(set) var estimatedProgress = CGFloat(0.0)
        private(set) var canGoBack = false

        private var loadingStateObserver: NSKeyValueObservation?
        private var loadingProgressObserver: NSKeyValueObservation?
        private var canGoBackObserver: NSKeyValueObservation?
        private var urlChangeObserver: NSKeyValueObservation?

        init(configuration: WKWebViewConfiguration,
             rootUrl: URL,
             userScripts: WebViewUserScriptsProtocol? = nil,
             allowsBackForwardNavigationGestures: Bool = true,
             urlChangeAction: UrlChangeAction? = nil) {
            self.configuration = configuration
            self.rootUrl = rootUrl
            self.userScripts = userScripts
            self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
            self.urlChangeAction = urlChangeAction

            super.init()

            // Default delegate to self.
            delegate = self

            addUserScripts(userScripts: userScripts)

            configure()
        }

        private func addUserScripts(userScripts: WebViewUserScriptsProtocol?) {
            guard let scripts = userScripts?.scripts else {
                return
            }

            configuration.userContentController.removeAllScriptMessageHandlers()
            for userScript in scripts {
                configuration.userContentController.addUserScript(userScript.script)
                configuration.userContentController.add(self, name: userScript.name)
            }
        }

        // Called by the webView:
        //   - mandatory to be called by the webView because of the parameter
        //   - it is the webView who knows what to do with the changes.
        private func configure() {
            guard let webView else {
                loadingStateObserver = nil
                loadingProgressObserver = nil
                canGoBackObserver = nil
                urlChangeObserver = nil
                return
            }
            webView.navigationDelegate = self

            loadingStateObserver = webView.observe(\.isLoading) { [weak self] webView, _ in
                self?.isLoading = webView.isLoading
            }

            loadingProgressObserver = webView.observe(\.estimatedProgress) { [weak self] webView, _ in
                self?.estimatedProgress = webView.estimatedProgress
            }

            canGoBackObserver = webView.observe(\.canGoBack) { [weak self] webView, _ in
                self?.canGoBack = webView.canGoBack
            }

            urlChangeObserver = webView.observe(\.url) { [weak self] webView, _ in
                guard let self else {
                    return
                }
                urlChangeAction?(self, webView.url)
            }
        }

        @MainActor // `evaluateJavaScript` must be used from main thread only.
        func readInLocalStorage(key: String) async -> Any? {
            guard let webView else {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage not called because no webView initialzed")
                return nil
            }

            // Prepare javaScript script.
            let script = "localStorage.getItem('\(key)');"

            do {
                // Execute javaScript script
                let value = try await webView.evaluateJavaScript(script)
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage success - `\(key)` -> `\(value.debugDescription, privacy: .private)`")
                return value
            } catch {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) ReadInLocalStorage failed to read key `\(key)`: \(error)")
                return nil
            }
        }

        @MainActor // `evaluateJavaScript` must be used from main thread only.
        func writeInLocalStorage(key: String, value: String) async {
            guard let webView else {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage not called because no webView initialzed")
                return
            }

            // Prepare javaScript script.
            let script = "localStorage.setItem('\(key)', '\(value)');"

            do {
                // Execute javaScript script
                _ = try await webView.evaluateJavaScript(script)
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage success - `\(key)` = `\(value, privacy: .private)`")
            } catch {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) WriteInLocalStorage failed to set key `\(key)` to value `\(value, privacy: .private)`: \(error)")
            }
        }

        func goBack() {
            webView?.goBack()
        }

        @MainActor
        func goBackToRootUrl() {
            guard let webView,
                  let firstItem = webView.backForwardList.backList.first,
                  firstItem.initialURL == rootUrl else {
                return
            }
            webView.go(to: firstItem)
        }
    }
}

extension SwiftUIWebView.ViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Dispatch message to message handler, passing the view model to be able to act on it.
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) didReceive message: \(message.name)")
        userScripts?.userScriptEmittedMessage(message, for: self)
    }
}

extension SwiftUIWebView.ViewModel: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) heck if navigation is allowed to \(navigationAction.request.url?.absoluteString ?? "<no destination URL found>")")
        return true
    }

    func navigationWillStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation will start")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did start")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did finish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Navigation did failed with error: \(error)")
    }
}

extension SwiftUIWebView.ViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.request.url != nil else {
            decisionHandler(.cancel)
            return
        }

        // Check with delegate if navigation to destination is allowed.
        if let delegate,
           !delegate.checkIfNavigationIsAllowed(navigationAction: navigationAction) {
            decisionHandler(.cancel)
        } else {
            delegate?.navigationWillStart(navigationAction: navigationAction)
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        #if DEBUG
            if acceptSelfSignedCertificate,
               challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        #endif

        completionHandler(.performDefaultHandling, nil)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.navigationDidStart()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.navigationDidFailed(withError: error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        delegate?.navigationDidFailed(withError: error)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.navigationDidFinish()
    }
}

extension SwiftUIWebView.ViewModel {
    static let `default` = {
        let model = SwiftUIWebView.ViewModel(configuration: WKWebViewConfiguration(),
                                             rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                             userScripts: HomeUserScripts())
        model.delegate = WebViewDelegateSimulatorImplementation()
        #if DEBUG
            model.acceptSelfSignedCertificate = true
        #endif
        model.urlChangeAction = { _, url in
            AppLog.viewModel.notice("\(AppLog.logHeader(SwiftUIWebView.ViewModel.self)) Url did change to \(url.debugDescription)")
        }
        return model
    }()
}
