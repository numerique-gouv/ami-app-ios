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

        let configuration = WKWebViewConfiguration()
        let rootUrl: URL
        weak var delegate: WebViewDelegate?
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

        init(websiteDataStore: WKWebsiteDataStore,
             rootUrl: URL,
             initialUserScripts: WebViewUserScriptsProtocol? = nil,
             allowsBackForwardNavigationGestures: Bool = true,
             urlChangeAction: UrlChangeAction? = nil) {
            configuration.websiteDataStore = websiteDataStore
            self.rootUrl = rootUrl
            userScripts = initialUserScripts
            self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
            self.urlChangeAction = urlChangeAction

            super.init()

            // Default delegate to self.
            delegate = self

            addUserScripts(userScripts: initialUserScripts)

            configure()

            AppLog.viewModel.info("\(AppLog.logHeader(self)) Don't foget to call `loadInitialPage()` in your subclass to load your webView content when your ViewModel is fully ready.")
        }

        private func addUserScripts(userScripts: WebViewUserScriptsProtocol?) {
            guard let scripts = userScripts?.scripts else {
                return
            }

            removeAllUserScripts()
            for userScript in scripts {
                configuration.userContentController.addUserScript(userScript.script)
                // Use WeakScriptMessageHandler to avoid retain cycle:
                //   WebView.ViewModel -> WKWebViewConfiguration -> WKUserContentController -> WebView.ViewModel (self)
                configuration.userContentController.add(WeakScriptMessageHandler(self), name: userScript.name)
            }
        }

        private func removeAllUserScripts() {
            // WKUserContentController holds a strong reference to every registered
            // WKScriptMessageHandler, which would create a retain cycle because
            // `configuration` is also strongly held by this view model.
            configuration.userContentController.removeAllScriptMessageHandlers()
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

        deinit {
            // Remove all user scripts to be sure to not keep a reference
            // to a message handler that could cause a retain cycle.
            removeAllUserScripts()
        }

        func goBack() {
            webView?.goBack()
        }

        @MainActor
        func loadInitialPage() {
            webView?.load(URLRequest(url: rootUrl))
        }

        // The `goBackToRootUrl()` method doesn't seem to work reliably with Single Page Application in WKWebView.
        // The web page seems to be blocked on a blank page during loading.
        @MainActor
        func goBackToRootUrl() {
            guard let webView,
                  let firstItem = webView.backForwardList.backList.first,
                  firstItem.initialURL == rootUrl else {
                return
            }
            webView.go(to: firstItem)
        }

        // Delete all local data and cookies associated with the current web session.
        @MainActor
        func deleteSessionLocalData() async {
            let records = await configuration.websiteDataStore.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes())
            for record in records {
                await configuration.websiteDataStore.removeData(ofTypes: record.dataTypes, for: [record])
            }
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
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) Check if navigation is allowed to \(navigationAction.request.url?.absoluteString ?? "<no destination URL found>")")
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
    static let simulatorDelegate = WebViewDelegateSimulatorImplementation()
    static let `default` = {
        let model = SwiftUIWebView.ViewModel(websiteDataStore: .nonPersistent(),
                                             rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                             initialUserScripts: HomeUserScripts())
        model.delegate = simulatorDelegate
        #if DEBUG
            model.acceptSelfSignedCertificate = true
        #endif
        model.urlChangeAction = { _, url in
            AppLog.viewModel.notice("\(AppLog.logHeader(SwiftUIWebView.ViewModel.self)) Url did change to \(url.debugDescription)")
        }
        return model
    }()
}
