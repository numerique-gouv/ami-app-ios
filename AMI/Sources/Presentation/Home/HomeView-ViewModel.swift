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
        // The name of the cookie containing the authentication token.
        private static let AUTHENTICATION_COOKIE_NAME = "token"
        enum Partner: Hashable {
            case generic(URL)
        }

        private let notificationManager: NotificationManager
        let webViewViewModel: SwiftUIWebView.ViewModel
        let settingsViewViewModel: SettingsView.ViewModel
        var onboardingViewViewModel: OnboardingView.ViewModel?

        var isOnContactPage = false
        var showSettings = false
        var showNoEmailClientAlert = false
        var isPresentingOnboardingView = false
        // Temporarily display back button when on OIDC page.
        var showBackButton = false

        private var checkNotificationStatusDone = false

        var selectedPartner: Partner?
        enum Event {
            case navigateToRootUrl
        }

        let eventsStream = PassthroughSubject<Event, Never>()

        @Sendable
        private func handleUrlChange(webViewViewModel: SwiftUIWebView.ViewModel, url: URL?) {
            let shoudlShowNotificationsSettings = SpecialWebPageUrl.notificationsSettings.match(url)
            isOnContactPage = SpecialWebPageUrl.contact.match(url)

            print("[HomeView-ViewModel]: URL Change Action \(url?.debugDescription ?? "<nil>")\n\tsettings: \(showSettings) - contact: \(isOnContactPage)")

            Task { @MainActor in
                if shoudlShowNotificationsSettings,
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
            let userScripts = HomeUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(configuration: SwiftUIWebView.sharedConfiguration,
                                                            rootUrl: rootUrl,
                                                            userScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.notificationManager = notificationManager
            settingsViewViewModel = SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                print("[HomeView-ViewModel]: notificationsSettingDidChangeAction")
                Task { @MainActor in
                    await webViewViewModel.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })

            super.init()

            self.webViewViewModel.delegate = self

            // Init `urlChangeAction` property after fully initialized `self` because closure is referencing `self`.
            // No clean way to pass this closure in the `SwiftUIWebView.ViewModel.init` call.
            webViewViewModel.urlChangeAction = handleUrlChange
            userScripts.userLoggedInAction = userLoginActions
            userScripts.userLoggedOutAction = userLogoutActions
        }

        private func userLoginActions() {
            // Check if user made a choice about allowing Push notifications reception.
            checkNotificationStatus()
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

            // Prepare Onboarding View Model now that we have all required datas.
            notificationManager.userAuthenticationToken = userAuthenticationToken
            onboardingViewViewModel = OnboardingView.ViewModel(applicationRootUrl: webViewViewModel.rootUrl,
                                                               notificationManager: notificationManager)
            onboardingViewViewModel?.eventReceiver = { event in
                switch event {
                case .isDismissed:
                    // Go back to root URL (to leave web page)
                    self.webViewViewModel.goBackToRootUrl()
                    self.isPresentingOnboardingView = false
                    self.onboardingViewViewModel = nil
                }
            }

            Task { @MainActor in
                isPresentingOnboardingView = true
            }
        }

        private func userLogoutActions() {
            // Reset Notification status check when on logout to recheck it on next login.
            checkNotificationStatusDone = false

            // TODO: we should reset web session here to destroy any user data.
            // Currently, on next login, FC find the previous token and reconnect automatically with previous profile.

            webViewViewModel.goBackToRootUrl()
        }

        // Get the auth token from cookie store.
        // Return nil if no token is found.
        private var getUserAuthenticationToken: String? {
            get async {
                await webViewViewModel.configuration
                    .websiteDataStore
                    .httpCookieStore
                    .allCookies()
                    .first(where: { $0.name == Self.AUTHENTICATION_COOKIE_NAME })?.value.replacingOccurrences(of: "\"", with: "")
            }
        }

        func partnerViewModel(for url: URL) -> PartnerView.ViewModel {
            // Init Partner's view with the HomeView web configuration (to share cookies and tokens).
            PartnerView.ViewModel(configuration: webViewViewModel.configuration, rootUrl: url)
        }
    }
}

extension HomeView.ViewModel: WebViewDelegate {
    func checkIfNavigationIsAllowed(navigationAction: WKNavigationAction) -> Bool {
        guard let targetUrl = navigationAction.request.url else {
            // No special restriction. Return TRUE.
            return true
        }

        // Special process for `mailto` url.
        if targetUrl.scheme == "mailto" {
            Task { @MainActor in
                contactByEmail(targetUrl: targetUrl)
            }
            return false
        }

        // Special case of OIDC web page for HomeView
        // Continue normal navigation inside the Home webView.
        //
        // Connection pages is special for now because we can be blocked
        // on France Connect page when loging out without any way to exit the error page.
        // So let's the back button be present.
        //
        if let targetHost = targetUrl.host(),
           Config.shared.OIDC_HOSTS.contains(targetHost) {
            showBackButton = true
            return true
        } else {
            showBackButton = false
        }

        // Special case of "about:blank" (used on FI impots.gouv.fr)
        if targetUrl.host() == nil {
            return true
        }

        // Special process for partner Url
        if !targetUrl.absoluteString.hasPrefix(webViewViewModel.rootUrl.absoluteString) {
            selectedPartner = .generic(targetUrl)
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
