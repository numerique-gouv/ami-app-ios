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

    @State private var activateNotification = false
    @State private var isAutoUpdated = false

    var body: some View {
        NavigationStack {
            List {
                Toggle(isOn: $activateNotification) {
                    Text("Activer les notifications")
                    Text("Recevoir les notifications sur mon appareil mobile")
                }
                .toggleStyle(SwitchToggleStyle(tint: Asset.Colors.blueFranceSun113.swiftUIColor))
            }
            .onChange(of: activateNotification) { _, newValue in
                guard !isAutoUpdated else {
                    isAutoUpdated = false
                    return
                }
                switch newValue {
                case true: NotificationHelper.requestPermission()
                case false: NotificationHelper.resetAuthorization()
                }
            }
            .navigationTitle("Paramètres")
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
