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
    typealias UrlChangeAction = @Sendable (SwiftUIWebView.ViewModel, URL?) -> Void

    @Observable
    class ViewModel: NSObject {
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
        let delegate: WebViewDelegate?
        let userScripts: WebViewUserScripts?
        let allowsBackForwardNavigationGestures: Bool
        let acceptSelfSignedCertificate: Bool

        private(set) var isLoading = false
        private(set) var estimatedProgress = CGFloat(0.0)
        private(set) var canGoBack = false

        private var loadingStateObserver: NSKeyValueObservation?
        private var loadingProgressObserver: NSKeyValueObservation?
        private var canGoBackObserver: NSKeyValueObservation?
        private var urlChangeObserver: NSKeyValueObservation?

        init(configuration: WKWebViewConfiguration,
             rootUrl: URL,
             delegate: WebViewDelegate? = nil,
             userScripts: WebViewUserScripts? = nil,
             allowsBackForwardNavigationGestures: Bool = true,
             acceptSelfSignedCertificate: Bool = false,
             urlChangeAction: UrlChangeAction? = nil) {
            self.configuration = configuration
            self.rootUrl = rootUrl
            self.delegate = delegate
            self.userScripts = userScripts
            self.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
            self.acceptSelfSignedCertificate = acceptSelfSignedCertificate
            self.urlChangeAction = urlChangeAction

            super.init()

            addUserScripts(userScripts: userScripts)

            configure()
        }

        private func addUserScripts(userScripts: WebViewUserScripts?) {
            guard let scripts = userScripts?.scripts else {
                return
            }

            for userScript in scripts {
                configuration.userContentController.removeAllUserScripts()
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

        func goBack() {
            webView?.goBack()
        }
    }
}

extension SwiftUIWebView.ViewModel: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Dispatch message to message handler, passing the view model to be able to act on it.
        userScripts?.userScriptEmittedMessage(message, for: self)
    }
}

extension SwiftUIWebView.ViewModel: WebViewDelegate {
    func navigationWillStart() {
        print("[WebViewDelegate] Navigation will start")
    }

    func navigationDidStart() {
        print("[WebViewDelegate] Navigation did start")
    }

    func navigationDidFinish() {
        print("[WebViewDelegate] Navigation did finish")
    }

    func navigationDidFailed(withError error: Error) {
        print("[WebViewDelegate] Navigation did failed with error: \(error)")
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

        delegate?.navigationWillStart(navigationAction: navigationAction)

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView,
                 didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if acceptSelfSignedCertificate,
           challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
            return
        }

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

#if DEBUG
    extension SwiftUIWebView.ViewModel {
        static let `default` = {
            let model = SwiftUIWebView.ViewModel(configuration: WKWebViewConfiguration(),
                                                 rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                                 delegate: WebViewDelegateSimulatorImplementation(),
                                                 userScripts: HomeUserScripts(),
                                                 acceptSelfSignedCertificate: true)
            model.urlChangeAction = { viewModel, url in
                print("[SwiftUIWebView.ViewModel] url did change to \(url.debugDescription)")
            }
            return model
        }()
    }
#endif
