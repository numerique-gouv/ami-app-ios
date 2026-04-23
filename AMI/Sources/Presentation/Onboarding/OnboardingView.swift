//
//  OnboardingView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 16/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ViewModel

    @ViewBuilder
    private var title: some View {
        Text("Activez les notifications pour suivre vos démarches")
            .font(.title2)
            .bold()
            .foregroundStyle(Color(hex: 0x161616))
    }

    @ViewBuilder
    private var message: some View {
        Text("Recevez des alertes de suivi et des rappels utiles quand vous en avez besoin. Vous pourrez les désactiver à tout moment.")
            .font(.body)
            .foregroundStyle(Color(hex: 0x3A3A3A))
    }

    @ViewBuilder
    private var activateButton: some View {
        Button {
            viewModel.processAction(.activate)
        } label: {
            Text("Activer")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(DsfrButtonStyle(type: .primary))
    }

    @ViewBuilder
    private var laterButton: some View {
        Button {
            viewModel.processAction(.later)
        } label: {
            Text("Peut-être plus tard")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(DsfrButtonStyle(type: .secondary))
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.processAction(.close)
                dismiss()
            } label: {
                Text(AMIL10n.commonClose)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0.0) {
                Asset.Images.onboardingNotifications.swiftUIImage

                title
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16.0)

                message
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16.0)

                activateButton
                    .padding(.top, 40.0)

                laterButton
                    .padding(.top, 16.0)
            }
            .padding(.horizontal, 16.0)
            .toolbar {
                toolbar
            }
        }
    }
}

#Preview {
    OnboardingView(
        viewModel: OnboardingView.ViewModel(
            applicationRootUrl: URL(
                string: "https://google.com"
            )!,
            notificationManager: NotificationManager()
        ))
}
