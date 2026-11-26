//
//  HomeViewModel.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Combine
import Foundation
import UIKit
import WebKit

@MainActor
@Observable
class HomeViewModel: NSObject {
    /// The name of the cookie containing the authentication token.
    private static let AUTHENTICATION_COOKIE_NAME = "token"

    // MARK: - Dependencies

    /// Dependencies received as parameters or built during initialisation.
    let notificationManager: NotificationManager
    let webViewViewModel: SwiftUIWebView.ViewModel
    // PromotedUrls Feature
    var promotedUrls: PromotedUrlsFeature?

    // MARK: - States

    /// Flags observed by View to update its state
    var isPresentingSettings = false
    var isPresentingNotificationsActivationDialog = false
    var selectedDestination: ServiceLinkViewModel?
    // Temporarily display back button when on OIDC page.
    var showBackButton = false

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
        userScripts.presentNotificationsActivationDialogAction = presentNotificationsActivationDialog

        // Set NotificationManager base URL to register the device to AMI backend to allow Push Notifications.
        setNotificationManagerBaseUrl(rootUrl)

        Task { @MainActor in
            // Inject script presenting native infos to web application.
            let nativeInfosScript = await HomeNativeInfosScripts()
            webViewViewModel.addUserScripts(userScripts: nativeInfosScript)

            // Inject script presenting application state (like Push Notifications activation) to web application.
            let nativeAppStateScript = await HomeNativeAppStateScripts()
            webViewViewModel.addUserScripts(userScripts: nativeAppStateScript)

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
        }
    }

    private func userLogoutActions() {
        // Reset NotificationManager `userAuthenticationToken`.
        resetNotificationManagerUserAuthentificationToken()

        Task { @MainActor in
            // Remove all session data to avoid reusing automatically them on next connection.
            await webViewViewModel.localStorageManager?.deleteSessionLocalData()
            webViewViewModel.goBackToRootUrl()
        }
    }

    private func webappIsReadyAction() {
        Task {
            // Push the current value whenever the web app reports itself ready, so a
            // fresh document (page reload or web process crash) gets the actual value
            // instead of the one baked in at web view setup (see
            // `SwiftUIWebView.ViewModel.webViewWebContentProcessDidTerminate`).
            await updateNativeAppStatePushNotificationEnabled()

            // PromotedUrls Feature
            //
            // Prepare the PromotedUrls Feature viewModel when the web app is ready.
            // This will load the aliased URLs catalog using `loadUrlAliasedUrls` method.
            await promotedUrls?.viewModel.prepare()
        }
    }

    private func presentNotificationsActivationDialog() {
        isPresentingNotificationsActivationDialog = true
    }

    // MARK: - Notifications (allow push notifications) management

    private func setNotificationManagerBaseUrl(_ url: URL) {
        notificationManager.setBaseUrl(url)
    }

    private func setNotificationManagerUserAuthentificationToken(_ token: String) {
        notificationManager.setUserAuthenticationToken(token)
    }

    private func resetNotificationManagerUserAuthentificationToken() {
        notificationManager.setUserAuthenticationToken(nil)
    }

    /// Called by the NotificationEventHandler implementation if Url matches `rootUrl`.
    func handleIncomingUrl(url: URL) {
        guard let notificationPageUrl = URL(string: "/#/notifications", relativeTo: url) else {
            return
        }

        Task { @MainActor in
            // Dismiss any Service view.
            backToHomeViewAction()
            // Go to Notifications screen.
            webViewViewModel.webView?.load(URLRequest(url: notificationPageUrl))
        }
    }

    /// Dismiss the Notifications activation dialog and presents the Settings sheet.
    func confirmActivateNotificationsDialog() {
        isPresentingNotificationsActivationDialog = false
        isPresentingSettings = true
    }

    /// Dismiss the Notifications activation dialog.
    func cancelActivateNotificationsDialog() {
        isPresentingNotificationsActivationDialog = false
    }

    /// Pushes the current push-notification state to the web app's `NativeAppState.pushNotificationEnabled`.
    func updateNativeAppStatePushNotificationEnabled() async {
        let pushNotificationEnabled = await NotificationStatus.isEnabled()
        do {
            try await webViewViewModel.webView?.evaluateJavaScript(HomeNativeAppStateScripts.javascriptToUpdatePushNotificationEnabled(pushNotificationEnabled))
        } catch {
            AppLog.viewModel.notice("\(AppLog.logHeader(self)) Error updating NativeAppState `pushNotificationEnabled`: \(error)")
        }
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
    }
}

extension HomeViewModel: NotificationEventHandler {
    /// The action called by the Notification Publisher when a NotificationEvent is received.
    func handleReceivedNotificationEvent(event: NotificationEvent) async {
        // Only handle user tapped notification.
        guard case .userResponse = event.source else {
            return
        }

        // Call action only if the host of the application URL of the notification payload matches the base domain.
        if let targetApplicationUrl = try? event.decodePayload(as: NotificationEventPayload.self)?.applicationUrl,
           targetApplicationUrl.host() == webViewViewModel.rootUrl.host() {
            await handleIncomingUrl(url: targetApplicationUrl)
        } else {
            AppLog.viewModel.warning("\(AppLog.logHeader(self)) Unable to handle incoming notification event:\t\(event)")
        }
    }
}
