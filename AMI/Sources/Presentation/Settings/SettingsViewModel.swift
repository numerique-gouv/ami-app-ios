//
//  SettingsViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 27/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

@MainActor
@Observable
final class SettingsViewModel: NSObject {
    typealias NotificationsSettingDidChangeAction = (Bool) -> Void

    private let notificationManager: NotificationManager
    private let notificationsSettingDidChangeAction: NotificationsSettingDidChangeAction?

    var isNotificationsActive = false
    var isAutoUpdated = false

    init(notificationManager: NotificationManager, notificationsSettingDidChangeAction: NotificationsSettingDidChangeAction? = nil) {
        self.notificationManager = notificationManager
        self.notificationsSettingDidChangeAction = notificationsSettingDidChangeAction
    }

    func updateNotificationAuthorizationStatus(autoUpdate: Bool) async {
        let notificationsActiveNewValue = await NotificationStatus.isNotificationEnabled()
        if notificationsActiveNewValue != isNotificationsActive {
            isAutoUpdated = autoUpdate
        }
        isNotificationsActive = notificationsActiveNewValue
        notificationsSettingDidChangeAction?(notificationsActiveNewValue)
    }

    func toggleNotificationPermissions(allowNotifications: Bool) {
        guard !isAutoUpdated else {
            isAutoUpdated = false
            return
        }
        switch allowNotifications {
        case true: NotificationStatus.requestPermission()
        case false: NotificationStatus.resetAuthorization()
        }
    }
}
