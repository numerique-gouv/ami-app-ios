//
//  ButtonDSFR.swift
//  AMI-lab-xcodegen
//
//  Created by Nicolas Buquet on 09/03/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct DsfrButtonStyle: ButtonStyle {
    enum DsfrButtonStyleType {
        case primary
        case secondary
    }

    let type: DsfrButtonStyleType

    private func color(configuration: Configuration) -> Color {
        switch type {
        case .primary: .white
        case .secondary: Asset.Colors.blueFranceSun113.swiftUIColor.opacity(configuration.isPressed ? 0.5 : 1.0)
        }
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        switch type {
        case .primary: Color(asset: Asset.Colors.blueFranceSun113).opacity(configuration.isPressed ? 0.5 : 1.0)
        case .secondary: .white
        }
    }

    @ViewBuilder
    private func background(configuration: Configuration) -> some View {
        switch type {
        case .primary: RoundedRectangle(cornerRadius: 4.0).fill(backgroundColor(configuration: configuration))
        case .secondary: RoundedRectangle(cornerRadius: 4.0).stroke(color(configuration: configuration))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .padding(16.0)
            .foregroundColor(color(configuration: configuration))
            .background {
                background(configuration: configuration)
            }
            // Full width
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 4.0))
        // .scaleEffect(configuration.isPressed ? 1.2 : 1)
        // .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
