//
//  SettingsView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 23/01/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import AmiDesignSystem
import SwiftUI

struct SettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss

    @Bindable var viewModel: ViewModel

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
    private var notificationStatus: some View {
        Toggle(isOn: $viewModel.isNotificationsActive) {
            Text(AMIL10n.settingsNotificationsAllowTitle)
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor)) // needed for Toggle widget.
        .disabled(true) // Can't change the settings using the toggle.
    }

    @ViewBuilder
    private var modifyNotificationSettings: some View {
        Button {
            viewModel.updateNotificationPermissions(allowNotifications: !viewModel.isNotificationsActive)
        } label: {
            Text("modifier")
        }
        .buttonStyle(ButtonStyleDsfr(type: .secondary))
    }

    var body: some View {
        NavigationStack {
            List {
                notificationStatus
                    .listRowSeparator(.hidden)
                modifyNotificationSettings
                    .fixedSize()
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
                        await viewModel.updateNotificationAuthorizationStatus(autoUpdate: true)
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
                await viewModel.updateNotificationAuthorizationStatus(autoUpdate: true)
            }
        }
    }
}

#Preview {
    let viewModel = SettingsView.ViewModel(notificationManager: NotificationManager())
    SettingsView(viewModel: viewModel)
}
