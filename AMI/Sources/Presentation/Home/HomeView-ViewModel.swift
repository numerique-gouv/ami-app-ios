//
//  HomeView-ViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Combine
import Foundation
import UIKit
import WebKit

extension HomeView {
    @Observable
    class ViewModel: NSObject {
        let webViewViewModel: SwiftUIWebView.ViewModel
        let settingsViewViewModel: SettingsView.ViewModel
        var onboardingViewViewModel: OnboardingView.ViewModel

        var isExternalProcess = false
        var isOnContactPage = false
        var showSettings = false
        var showNoEmailClientAlert = false
        var isPresentingOnboardingView = false

        private var checkNotificationStatusDone = false

        enum Event {
            case navigateToRootUrl
        }

        let eventsStream = PassthroughSubject<Event, Never>()

        @Sendable
        private func handleUrlChange(webViewViewModel: SwiftUIWebView.ViewModel, url: URL?) {
            showSettings = url?.absoluteString.hasSuffix("/#/settings") ?? false
            isOnContactPage = url?.absoluteString.hasSuffix("/#/contact") ?? false
            isExternalProcess = !(url?.absoluteString.hasPrefix(webViewViewModel.rootUrl.absoluteString) ?? true)

            print("[HomeView-ViewModel]: URL Change Action \(url?.debugDescription ?? "<nil>")\n\tsettings: \(showSettings) - contact: \(isOnContactPage) - external: \(isExternalProcess)")

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

        @MainActor
        func contactByEmail(targetUrl: URL) {
            UIApplication.shared.open(targetUrl) { accepted in
                self.showNoEmailClientAlert = !accepted
            }
        }

        init(rootUrl: URL, notificationManager: NotificationManager) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let homeUserScripts = HomeUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            userScripts: homeUserScripts)
            self.webViewViewModel = webViewViewModel
            settingsViewViewModel = SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                print("[HomeView-ViewModel]: notificationsSettingDidChangeAction")
                Task { @MainActor in
                    await webViewViewModel.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })
            onboardingViewViewModel = OnboardingView.ViewModel(applicationRootUrl: rootUrl, notificationManager: notificationManager)

            super.init()

            self.webViewViewModel.delegate = self

            // Init `urlChangeAction` property after fully initialized `self` because closure is referencing `self`.
            // No clean way to pass this closure in the `SwiftUIWebView.ViewModel.init` call.
            webViewViewModel.urlChangeAction = handleUrlChange
            homeUserScripts.userLoggedAction = checkNotificationStatus
            onboardingViewViewModel.eventReceiver = { event in
                switch event {
                case .isDismissed:
                    // Go back to root URL (to leave web page)
                    self.webViewViewModel.goBackToRootUrl()
                    self.isPresentingOnboardingView = false
                }
            }
        }

        private func checkNotificationStatus() {
            // User logged event is called too often.
            // Only check Notifications Status once par session.
            // TODO: reset `checkNotificationStatusDone` on user disconnection.
            guard !checkNotificationStatusDone else {
                return
            }
            checkNotificationStatusDone = true
            Task {
                isPresentingOnboardingView = await NotificationStatus.notificationsAuthorizationStatus() == .notDetermined
            }
        }
    }
}

extension HomeView.ViewModel: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        if let targetUrl = navigationAction.request.url,
           targetUrl.scheme == "mailto" {
            Task { @MainActor in
                contactByEmail(targetUrl: targetUrl)
            }
            return false
        }
        return true
    }

    func navigationWillStart(navigationAction: WKNavigationAction) {
        print("[WebViewDelegate navigationWillStart]")
    }

    func navigationDidStart() {
        print("[WebViewDelegate navigationDidStart]")
    }

    func navigationDidFinish() {
        print("[WebViewDelegate navigationDidFinish]")
    }

    func navigationDidFailed(withError error: Error) {
        print("[WebViewDelegate navigationDidFailed] failed with error \(error)")
    }
}
