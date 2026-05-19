//
//  HomeView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension HomeView {
    @Observable
    class ViewModel: NSObject {
        let webViewViewModel: SwiftUIWebView.ViewModel
        let settingsViewViewModel: SettingsView.ViewModel

        var isExternalProcess = false
        var isOnContactPage = false
        var showSettings = false

        @Sendable
        private func handleUrlChange(webViewViewModel: SwiftUIWebView.ViewModel, url: URL?) {
            showSettings = url?.absoluteString.hasSuffix("/#/settings") ?? false
            isOnContactPage = url?.absoluteString.hasSuffix("/#/contact") ?? false
            isExternalProcess = !(url?.absoluteString.hasPrefix(webViewViewModel.rootUrl.absoluteString) ?? true)

            // swiftformat:disable redundantSelf
            AppLog.viewModel.notice(
                """
                \(AppLog.logHeader(self, function: #function)) URL Change Action \(url?.debugDescription ?? "<nil>")
                \tsettings: \(self.showSettings)
                \tcontact: \(self.isOnContactPage)
                \texternal: \(self.isExternalProcess)
                """
            )
            // swiftformat:enable redundantSelf

            Task { @MainActor in
                if self.showSettings,
                   self.webViewViewModel.webView?.canGoBack ?? false {
                    // As new page should not be handled by webview, reset webView last step navigation (to clean history).
                    self.webViewViewModel.webView?.goBack()
                    // Force `showSettings` to true because it is reset to false by the `goBack` command.
                    self.showSettings = true
                }
            }
        }

        func shareLogs() async {
            let userId = await webViewViewModel.readInLocalStorage(key: "user_fc_hash") as? String
            LogsExporter(userId: userId?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))).shareLogs()
        }

        init(rootUrl: URL, notificationManager: NotificationManager) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            delegate: HomeViewDelegate(),
                                                            userScripts: HomeUserScripts(notificationManager: notificationManager))
            self.webViewViewModel = webViewViewModel
            settingsViewViewModel = SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                Task { @MainActor in
                    await webViewViewModel.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })
            super.init()

            // Init `urlChangeAction` property after fully initialized `self` because closure is referencing `self`.
            // No clean way to pass this closure in the `SwiftUIWebView.ViewModel.init` call.
            webViewViewModel.urlChangeAction = handleUrlChange
        }
    }
}

class HomeViewDelegate: WebViewDelegate {
    func navigationWillStart(navigationAction: WKNavigationAction) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationWillStart")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidStart")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidFinish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self, function: #function)) NavigationDidFailed] failed with error \(error)")
    }
}
