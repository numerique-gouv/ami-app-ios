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
            let urlString = url?.absoluteString ?? ""
            isOnContactPage = urlString.hasSuffix("/#/contact") ?? false
            isExternalProcess = !urlString.hasPrefix(webViewViewModel.rootUrl.absoluteString)

            if let route = findNativeRoute(for: urlString) {
                Task { @MainActor in
                    switch route {
                    case .settings:
                        self.showSettings = true
                    }
                }
            }

            print("[HomeView-ViewModel]: URL Change Action \(url?.debugDescription ?? "<nil>")\n\tsettings: \(showSettings) - contact: \(isOnContactPage) - external: \(isExternalProcess)")
        }

        func shareLogs() async {
            let userId = await webViewViewModel.readInLocalStorage(key: "user_fc_hash") as? String
            LogsExporter(userId: userId?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))).shareLogs()
        }

        init(rootUrl: URL, notificationManager: NotificationManager) {
            // Assign first to local variable to be able to use it to instantiate `settingsViewViewModel` without referencing `self`.
            let homeUserScripts = HomeUserScripts(notificationManager: notificationManager)
            let webViewViewModel = SwiftUIWebView.ViewModel(rootUrl: rootUrl,
                                                            delegate: HomeViewDelegate(),
                                                            userScripts: homeUserScripts)
            self.webViewViewModel = webViewViewModel
            settingsViewViewModel = SettingsView.ViewModel(notificationManager: notificationManager, notificationsSettingDidChangeAction: { newValue in
                print("[HomeView-ViewModel]: notificationsSettingDidChangeAction")
                Task { @MainActor in
                    await webViewViewModel.writeInLocalStorage(key: "notifications_enabled", value: "\(newValue)")
                }
            })
            super.init()

            // Init `urlChangeAction` property after fully initialized `self` because closure is referencing `self`.
            // No clean way to pass this closure in the `SwiftUIWebView.ViewModel.init` call.
            webViewViewModel.urlChangeAction = handleUrlChange
            homeUserScripts.onNavigate = { [weak self] data in
                if let url = data as? String {
                    Task { @MainActor in
                        self?.handleRoute(routeString: url)
                    }
                }
            }
        }
    }
}

extension HomeView.ViewModel: WebRouteManagerProtocol {
    @MainActor
    func handleRoute(routeString: String) {
        if let route = findNativeRoute(for: routeString) {
            print("[HomeView-ViewModel]: Native route detected, navigating app to \(route)")
            switch route {
            case .settings:
                showSettings = true
            }
        } else {
            guard let url = URL(string: routeString, relativeTo: webViewViewModel.rootUrl) else { return }
            webViewViewModel.navigate(to: url)
        }
    }
}

class HomeViewDelegate: WebViewDelegate {
    func navigationWillStart(navigationAction _: WKNavigationAction) {
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
