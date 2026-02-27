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
    private var notificationToggle: some View {
        Toggle(isOn: $viewModel.isNotificationsActive) {
            Text(AMIL10n.settingsNotificationsAllowTitle)
        }
        .toggleStyle(SwitchToggleStyle(tint: .accentColor)) // needed for Toggle widget.
        // Use deprecated version of `onChange` to handle iOS back to iOS 15.
        .onChange(of: viewModel.isNotificationsActive) { newValue in
            viewModel.toggleNotificationPermissions(allowNotifications: newValue)
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
