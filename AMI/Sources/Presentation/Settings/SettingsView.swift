//
//  SettingsView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 23/01/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @State private var activateNotification = false
    @State private var isAutoUpdated = false

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                dismiss()
            } label: {
                Text(AMIL10n.commonClose)
            }
        }
    }

    @ViewBuilder
    private var notificationToggle: some View {
        Toggle(isOn: $activateNotification) {
            Text(AMIL10n.settingsNotificationsAllowTitle)
        }
        .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.blueFranceSun113.swiftUIColor))
        .onChange(of: activateNotification) { _, newValue in
            toggleNotificationPermissions(allowNotifications: newValue)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                notificationToggle
            }
            .toolbar {
                toolbar
            }
            .navigationTitle(AMIL10n.settingsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scenePhase, initial: true) { _, newPhase in
                switch newPhase {
                case .active:
                    Task {
                        await updateNotificationAuthorisationStatus(autoUpdate: true)
                    }
                case .inactive, .background:
                    break
                @unknown default:
                    break
                }
            }
        }
    }

    private func toggleNotificationPermissions(allowNotifications: Bool) {
        guard !isAutoUpdated else {
            isAutoUpdated = false
            return
        }
        switch allowNotifications {
        case true: NotificationHelper.requestPermission()
        case false: NotificationHelper.resetAuthorization()
        }
    }

    private func updateNotificationAuthorisationStatus(autoUpdate: Bool) async {
        let newActivcationValue = await NotificationHelper.notificationsAuthrizationStatus() == .authorized
        if newActivcationValue != activateNotification {
            isAutoUpdated = autoUpdate
        }
        activateNotification = newActivcationValue
    }
}

#Preview {
    SettingsView()
}
