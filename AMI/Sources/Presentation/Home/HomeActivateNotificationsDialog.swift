//
//  HomeActivateNotificationsDialog.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 26/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import AmiDesignSystem
import SwiftUI

struct HomeActivateNotificationsDialog: View {
    typealias ConfirmAction = () -> Void
    typealias CancelAction = () -> Void

    private let confirmAction: ConfirmAction
    private let cancelAction: CancelAction

    init(confirmAction: @escaping ConfirmAction, cancelAction: @escaping CancelAction) {
        self.confirmAction = confirmAction
        self.cancelAction = cancelAction
    }

    @ViewBuilder
    private var mainIcon: some View {
        Asset.Images.notifications.swiftUIImage
    }

    @ViewBuilder
    private var message: some View {
        Text(AMIL10n.activateNotificationsDialogMessage)
            .multilineTextAlignment(.center)
            .dsfrFont(.h5, lineSpacing: 0.0)
            .lineSpacing(0.0)
            .foregroundStyle(AmiDesignSystem.Colors.Text.Label.grey.swiftUIColor)
    }

    @ViewBuilder
    private var activateButton: some View {
        Button {
            confirmAction()
        } label: {
            Text(AMIL10n.activateNotificationsDialogButtonOkTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ButtonStyleDsfr(type: .primary))
    }

    @ViewBuilder
    private var cancelButton: some View {
        Button {
            cancelAction()
        } label: {
            Text(AMIL10n.activateNotificationsDialogButtonCancelTitle)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(ButtonStyleDsfr(type: .secondary))
    }

    var body: some View {
        VStack(spacing: 0.0) {
            mainIcon
            message
            activateButton
                .padding(.top, 16.0)
            cancelButton
                .padding(.top, 16.0)
        }
    }
}

#Preview {
    // swiftlint:disable applog_over_print
    HomeActivateNotificationsDialog(
        confirmAction: { print("Confirm action") },
        cancelAction: { print("Cancel action") }
    )
    // swiftlint:enable applog_over_print
}
