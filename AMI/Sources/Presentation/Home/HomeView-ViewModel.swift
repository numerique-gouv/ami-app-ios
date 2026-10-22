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
    @MainActor
    @Observable
    class ViewModel: NSObject {
        /// The name of the cookie containing the authentication token.
        private static let AUTHENTICATION_COOKIE_NAME = "token"
        /// Don't present Onboarding panel more than once a day.
        private static let MINIMUM_TIME_IMTERVAL_BETWEEN_ONBOARDING_NOTIFICATION = Double(24 * 60 * 60)

        // MARK: - Dependencies

        /// Dependencies received as parameters or built during initialisation.
        private let notificationManager: NotificationManager
        let webViewViewModel: SwiftUIWebView.ViewModel
        // PromotedUrls Feature
        var promotedUrls: PromotedUrlsFeature?

        // MARK: - States

        /// Flags observed by View to update its state
        var showSettings = false
        var isPresentingOnboardingView = false
        var selectedDestination: ServiceLinkViewModel?
        // Temporarily display back button when on OIDC page.
        var showBackButton = false

        private var lastOnboardingPresentationTime = Date.distantPast

        /// Flag to know if we can load initial page when coming back to webview, to reset initial state.
        /// Only used in `webViewReplacedAction` when we reset its state to Home state.
        private var modelIsFullyConfigured = false

        // MARK: - Init

        init(rootUrl: URL,
             websiteDataStore: WKWebsiteDataStore,
             specialLinkHandler: any SpecialLinkProtocol,
             notificationManager: NotificationManager) {
            let navigationHandler = HomeViewNavigationHandler(rootUrl: rootUrl,
                                                              specialLinkHandler: specialLinkHandler)
            let userScripts = HomeUserScripts()
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            websiteDataStore: websiteDataStore,
                                                            navigationHandler: navigationHandler,
                                                            navigationState: HomeViewNavigationState(baseUrl: rootUrl),
                                                            initialUserScripts: userScripts)
            self.webViewViewModel = webViewViewModel
            self.notificationManager = notificationManager

            super.init()

            // PromotedUrls Feature
            //
            promotedUrls = PromotedUrlsFeature(catalogProvider: loadUrlAliasedUrls)

            // Now that `self` is initialized, inject HomeViewModel and PromotedUrlsFeature into HomeViewNavigationHandler.
            navigationHandler.promotedUrls = promotedUrls
            navigationHandler.viewModel = self

            webViewViewModel.webViewReplacedAction = { [weak self] _ in
                guard let self,
                      modelIsFullyConfigured else {
                    return
                }

                loadInitialPage()
            }

            userScripts.userLoggedInAction = userLoginActions
            userScripts.userLoggedOutAction = userLogoutActions
            userScripts.webappIsReadyAction = webappIsReadyAction

            // Set NotificationManager base URL to register the device to AMI backend to allow Push Notifications.
            setNotificationManagerBaseUrl(rootUrl)

            Task { @MainActor in
                let nativeInfosScript = await HomeNativeInfosScripts()
                webViewViewModel.addUserScripts(userScripts: nativeInfosScript)
                modelIsFullyConfigured = true

                // Load initial page now that viewModel is fully ready.
                loadInitialPage()
            }
        }

        @MainActor
        private func loadInitialPage() {
            // Pass attached webView to `navigationState` to handle web page archiving.
            (webViewViewModel.navigationState as? HomeViewNavigationState)?.webView = webViewViewModel.webView
            webViewViewModel.loadInitialPage()
        }

        /// PromotedUrls Feature
        ///
        /// Aliased URLs loader
        ///
        @MainActor // `evaluateJavaScript` must be used from main thread only.
        @Sendable
        func loadUrlAliasedUrls() async throws(AliasedUrlsError) -> [AliasedUrlDTO] {
            guard let webView = webViewViewModel.webView else {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) webAppReadyPostActions not called because no webView initialzed")
                throw .pageNotReady
            }

            // Prepare javaScript script.
            let script = "window.WebAppBridge.getUrlAliases();"

            do {
                // Execute javaScript script
                guard let urlAliasesString = try await webView.evaluateJavaScript(script) as? String,
                      let urlAliasesData = urlAliasesString.data(using: .utf8) else {
                    throw AliasedUrlsError.invalidPayload
                }

                let urlAliasesDto = try JSONDecoder().decode([AliasedUrlDTO].self, from: urlAliasesData)
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) webAppReadyPostActions success")
                return urlAliasesDto
            } catch {
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) webAppReadyPostActions failed to execute: \(error)")
                throw .invalidPayload
            }
        }

        // MARK: - Actions triggered by webview JS events.

        private func userLoginActions() {
            // Check if user made a choice about allowing Push notifications reception.
            Task {
                guard let userAuthenticationToken = await getUserAuthenticationToken else {
                    // Unable to get user authentication token. Exit.
                    AppLog.viewModel.notice("\(AppLog.logHeader(self)) Unable to get User Authentication token")
                    return
                }

                // Set NotificationManager `userAuthenticationToken` now we have it
                // because a token renew can happen anytime if user already allowed notifications.
                setNotificationManagerUserAuthentificationToken(userAuthenticationToken)

                // Now that user is logged and we have its authentication token, we can proceed to
                // check its notification status and register to backend if needed.
                await checkNotificationStatus()
            }
        }

        private func userLogoutActions() {
            // Reset NotificationManager `userAuthenticationToken`.
            resetNotificationManagerUserAuthentificationToken()

            // Reset Notification status check when on logout to recheck it on next login.
            resetLastOnboardingPresentationTime()

            Task { @MainActor in
                // Remove all session data to avoid reusing automatically them on next connection.
                await webViewViewModel.localStorageManager?.deleteSessionLocalData()
                webViewViewModel.goBackToRootUrl()
            }
        }

        private func webappIsReadyAction() {
            Task {
                // PromotedUrls Feature
                //
                // Prepare the PromotedUrls Feature viewModel when the web app is ready.
                // This will load the aliased URLs catalog using `loadUrlAliasedUrls` method.
                await promotedUrls?.viewModel.prepare()
            }
        }

        // MARK: - Onboarding (allow push notifications) panel presentation management

        /// Check if Push Notifications are allowed and present Onboarding panel if necessary.
        /// Called by `userLoginAction`.
        private func checkNotificationStatus() async {
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
                // Apple recommends it ("Each time your app launches, it must register with APNs")
                //   https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/HandlingRemoteNotifications.html
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            @unknown default:
                AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unknown Notification Authorization Status")
            }

            // Only check Notifications Status once par session.
            guard shouldPresentOnboardingView else {
                return
            }
            setLastOnboardingPresentationTimeToNow()

            Task { @MainActor in
                isPresentingOnboardingView = true
            }
        }

        private func lastOnboardingPresentationTimeIsExpired() -> Bool {
            Date.now.timeIntervalSince(lastOnboardingPresentationTime) > Self.MINIMUM_TIME_IMTERVAL_BETWEEN_ONBOARDING_NOTIFICATION
        }

        private func setLastOnboardingPresentationTimeToNow() {
            lastOnboardingPresentationTime = .now
        }

        private func resetLastOnboardingPresentationTime() {
            lastOnboardingPresentationTime = .distantPast
        }

        private func setNotificationManagerBaseUrl(_ url: URL) {
            notificationManager.setBaseUrl(url)
        }

        private func setNotificationManagerUserAuthentificationToken(_ token: String) {
            notificationManager.setUserAuthenticationToken(token)
        }

        private func resetNotificationManagerUserAuthentificationToken() {
            notificationManager.setUserAuthenticationToken(nil)
        }

        // MARK: - View models builders

        // TODO: move this method into a DI module.
        /// View model built on-demand when the View need it.
        /// - makeSettingsViewViewModel : the view model needed when accessing the Notifications settings panel.
        func makeNotificationsSettingsViewViewModel() -> SettingsView.ViewModel {
            SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                AppLog.viewModel.notice("\(AppLog.logHeader(self)) notificationsSettingDidChangeAction")
                Task { @MainActor in
                    await self.webViewViewModel.localStorageManager?.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })
        }

        // TODO: move this method into a DI module.
        /// View model built on-demand when the View need it.
        /// - makeOnboardingViewViewModel : the view model needed when asking the user if receiving push notifications is allowed.
        func makeOnboardingViewViewModel() -> OnboardingView.ViewModel {
            let onboardingViewViewModel = OnboardingView.ViewModel(notificationManager: notificationManager)
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

        // MARK: - Helpers

        /// Get the auth token from cookie store.
        /// Return nil if no token is found.
        private var getUserAuthenticationToken: String? {
            get async {
                await webViewViewModel.configuration
                    .websiteDataStore
                    .httpCookieStore
                    .allCookies()
                    .first(where: { $0.name == Self.AUTHENTICATION_COOKIE_NAME })?.value.replacingOccurrences(of: "\"", with: "")
            }
        }

        /// The action to execute when the user comes back to this view.
        /// Used by WebViewNavigationhandler as action to call when dismissing the pushed view.
        func backToHomeViewAction() {
            AppLog.viewModel.log("\(AppLog.logHeader(self)) call")
            selectedDestination = nil
            sendCommand(command: .resetViewToHome)
        }

        // MARK: - Commands Stream

        @ObservationIgnored private var commandContinuation = [UUID: AsyncStream<HomeViewCommand>.Continuation]()
        @ObservationIgnored private var commandPending: [HomeViewCommand] = []

        /// Generate new command stream when view regenerates.
        func commandStream() -> AsyncStream<HomeViewCommand> {
            // Unique ID for this new command stream
            let id = UUID()

            // Create the command stream.
            let (stream, continuation) = AsyncStream.makeStream(
                of: HomeViewCommand.self,
                bufferingPolicy: .bufferingNewest(8)
            )

            // Store the AsyncStream.Continuation asssociated with this ID.
            commandContinuation[id] = continuation

            // Send any pending command.
            for command in commandPending {
                continuation.yield(command)
            }

            // Remove any pending command.
            commandPending.removeAll()

            return stream
        }

        /// Send the command through every registered command streams.
        /// If no command stream accepted the command, append the command to the pending list
        /// to be dispatched on next initied command stream.
        private func sendCommand(command: HomeViewCommand) {
            var delivered = false

            // With every command stream
            for (id, continuation) in commandContinuation {
                // Try to send command with existing continuation.
                // If the stream is already terminated, remove it from continuations.
                if case .terminated = continuation.yield(command) {
                    commandContinuation[id] = nil
                } else {
                    // Else, check the command as delivered.
                    delivered = true
                }
            }

            // If no stream was available to deliver the command, appends it to pending commands.
            // The pending commands will be picked up next time an AsyncStream is needed by a regenerated view.
            if !delivered {
                commandPending.append(command)
            }
        }
    }
}
