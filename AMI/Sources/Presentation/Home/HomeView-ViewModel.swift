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
        private static let MINIMUM_TIME_IMTERVAL_BETWEEN_ONBOARDING_NOTIFICATION = Double(24 * 60 * 60)

        enum Partner: Hashable {
            case generic(URL)
        }

        private let notificationManager: NotificationManager
        let webViewViewModel: SwiftUIWebView.ViewModel

        // Make `settingsViewViewModel` a computed property initialized on demand with available environment.
        var settingsViewViewModel: SettingsView.ViewModel {
            SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) notificationsSettingDidChangeAction")
                Task { @MainActor in
                    await self.webViewViewModel.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })
        }

        // Make `onboardingViewViewModel` a computed property initialized on demand with available environment.
        var onboardingViewViewModel: OnboardingView.ViewModel {
            let onboardingViewViewModel = OnboardingView.ViewModel(applicationRootUrl: webViewViewModel.rootUrl,
                                                                   notificationManager: notificationManager)
            onboardingViewViewModel.eventReceiver = { event in
                switch event {
                case .isDismissed:
                    // Go back to root URL (to leave web page)
                    Task { @MainActor in
                        self.webViewViewModel.goBackToRootUrl()
                        self.isPresentingOnboardingView = false
                    }
                }
            }

            return onboardingViewViewModel
        }

        var isOnContactPage = false
        var showSettings = false
        var showNoEmailClientAlert = false
        var isPresentingOnboardingView = false
        // Temporarily display back button when on OIDC page.
        var showBackButton = false

        private var lastCheckNotificationTime = Date.distantPast

        var selectedPartner: Partner?
        enum Event {
            case navigateToRootUrl
        }

        let eventsStream = PassthroughSubject<Event, Never>()

        @Sendable
        private func handleUrlChange(webViewViewModel: SwiftUIWebView.ViewModel, url: URL?) {
            let shoudlShowNotificationsSettings = SpecialWebPageUrl.notificationsSettings.match(url)
            isOnContactPage = SpecialWebPageUrl.contact.match(url)

            // swiftformat:disable redundantSelf
            AppLog.viewModel.notice(
                """
                \(AppLog.logHeader(self)) URL Change Action \(url?.debugDescription ?? "<nil>")
                \tsettings: \(self.showSettings)
                \tcontact: \(self.isOnContactPage)
                """
            )
            // swiftformat:enable redundantSelf

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
            let userScripts = HomeUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(configuration: SwiftUIWebView.sharedConfiguration,
                                                            rootUrl: rootUrl,
                                                            userScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.notificationManager = notificationManager

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
            Task {
                await checkNotificationStatus()
            }
        }

        private func lastOnboardingPresentationTimeIsExpired() -> Bool {
            Date.now.timeIntervalSince(lastCheckNotificationTime) > Self.MINIMUM_TIME_IMTERVAL_BETWEEN_ONBOARDING_NOTIFICATION
        }

        private func setLastOnboardingPresentationTimeToNow() {
            lastCheckNotificationTime = .now
        }

        private func resetLastOnboardingPresentationTime() {
            lastCheckNotificationTime = .distantPast
        }

        private func checkNotificationStatus() async {
            guard let userAuthenticationToken = await getUserAuthenticationToken else {
                // Unable to get user authentication token. Exit.
                print("[HomeView-ViewModel] getUserAuthenticationToken: Unable to get User Authentication token")
                return
            }

            var shouldPresentOnboardingView = false

            switch await NotificationStatus.notificationsAuthorizationStatus() {
            case .notDetermined:
                // User logged event is called too often.
                // Only check Notifications Status once par session.
                shouldPresentOnboardingView = lastOnboardingPresentationTimeIsExpired()
            case .denied:
                // No need to present Onboarding view: user already made its choice.
                break
            case .authorized, .provisional, .ephemeral:
                // Always call `registerForRemoteNotifications` to refresh Apns token if necessary.
                // Apple recommends it ("Each time your app launches, it must register with APNs"): https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/HandlingRemoteNotifications.html
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            @unknown default:
                print("[HomeView-ViewModel] checkNotificationStatus: Unknown Notification Authorization Status")
            }

            // Only check Notifications Status once par session.
            guard shouldPresentOnboardingView else {
                return
            }
            setLastOnboardingPresentationTimeToNow()

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
            resetLastOnboardingPresentationTime()

            Task { @MainActor in
                // Remove all session data to avoid reusing automatically them on next connection.
                await webViewViewModel.deleteSessionLocalData()
                webViewViewModel.goBackToRootUrl()
            }
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
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationWillStart")
    }

    func navigationDidStart() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidStart")
    }

    func navigationDidFinish() {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidFinish")
    }

    func navigationDidFailed(withError error: Error) {
        AppLog.viewModel.notice("\(AppLog.logHeader(self)) NavigationDidFailed] failed with error \(error)")
    }
}
