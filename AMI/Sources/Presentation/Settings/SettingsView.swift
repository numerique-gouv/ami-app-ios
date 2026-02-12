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

    @State private var isNotificationsActive = false
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
        Toggle(isOn: $isNotificationsActive) {
            Text(AMIL10n.settingsNotificationsAllowTitle)
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor)) // needed for Toggle widget.
        // Use deprecated version of `onChange` to handle iOS back to iOS 15.
        .onChange(of: isNotificationsActive) { newValue in
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
            // Use deprecated version of `onChange` to handle iOS back to iOS 15.
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    Task {
                        await updateNotificationAuthorizationStatus(autoUpdate: true)
                    }
                case .inactive, .background:
                    break
                @unknown default:
                    break
                }
            }
        }
        .task {
            Task {
                await updateNotificationAuthorizationStatus(autoUpdate: true)
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

    private func updateNotificationAuthorizationStatus(autoUpdate: Bool) async {
        let notificationsActiveNewValue = await NotificationHelper.isNotificationEnabled()
        if notificationsActiveNewValue != isNotificationsActive {
            isAutoUpdated = autoUpdate
        }
        isNotificationsActive = notificationsActiveNewValue
    }
}

#Preview {
    SettingsView()
}
