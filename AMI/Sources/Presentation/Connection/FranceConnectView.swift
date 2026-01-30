//
//  FranceConnectView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 30/01/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct FranceConnectView: View {
    let connectAction: () -> Void
    
    @ViewBuilder
    private var franceConnectButton: some View {
        Button {
            connectAction()
        } label: {
            HStack {
                Asset.Images.logoFranceConnect.swiftUIImage
                VStack {
                    Text(AMIL10n.connectFranceConnectSignin)
                    Text(AMIL10n.connectFranceConnectService)
                        .fontWeight(.bold)
                }
                .foregroundStyle(.white)
            }
            .padding(.vertical, 4.0)
            .padding(.horizontal, 16.0)
            .background(Asset.Colors.blueFranceSun113.swiftUIColor)
        }
    }

    @ViewBuilder
    private var franceConnectLink: some View {
        Link(AMIL10n.connectFranceConnectMore, destination: URL(string: "https://franceconnect.gouv.fr/")!)
            .underline()
            .environment(\.openURL, OpenURLAction { _ in
                if #available(iOS 26.0, *) {
                    return .systemAction(prefersInApp: true)
                }
                return .systemAction
            })
    }

    @ViewBuilder
    private var footer: some View {
        Text(AMIL10n.connectProblems)
            .font(.caption)
        Link(AMIL10n.connectContactUs, destination: URL(string: "https://www.tchap.gouv.fr/#/room/!pwyfzLTDXyMeinVsgL:agent.dinum.tchap.gouv.fr")!)
            .font(.caption)
            .underline()
            .environment(\.openURL, OpenURLAction { _ in
                if #available(iOS 26.0, *) {
                    return .systemAction(prefersInApp: true)
                }
                return .systemAction
            })
    }

    var body: some View {
        VStack {
            Spacer()
            
            Asset.Images.logoAmi.swiftUIImage
                .padding(.bottom, 32.0)

            Text(LocalizedStringKey(AMIL10n.connectMessage1))
                .font(.subheadline)
                .padding(.bottom, 32.0)

            Text(LocalizedStringKey(AMIL10n.connectMessage2))
                .font(.footnote)
                .padding(.bottom, 64.0)

            franceConnectButton
                .padding(.bottom)
            franceConnectLink

            Spacer()
            footer
        }
        .padding(.horizontal, 32.0)
    }
}

#Preview {
    FranceConnectView {
        print("Connect action!")
    }
}
