//
//  LocalStorageTestView.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 10/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct LocalStorageTestView: View {
    @Bindable var viewModel: SettingsView.ViewModel

    @ViewBuilder
    private var writeHighSecureValue: some View {
        Button {
            viewModel.writeHighSecureValue()
        } label: {
            Text("Write High Secure")
        }
        .buttonStyle(DsfrButtonStyle(type: .primary))
    }

    @ViewBuilder
    private var readHighSecureValue: some View {
        Button {
            viewModel.readHighSecureValue()
        } label: {
            Text("Read High Secure")
        }
        .buttonStyle(DsfrButtonStyle(type: .primary))
    }

    @ViewBuilder
    private var deleteHighSecureValue: some View {
        Button {
            viewModel.deleteHighSecureValue()
        } label: {
            Text("Delete High Secure")
        }
        .buttonStyle(DsfrButtonStyle(type: .primary))
    }

    @ViewBuilder
    private var localStorageAction: some View {
        TextField(text: $viewModel.localStorageAction) {
            Text("Action")
        }
    }

    var body: some View {
        writeHighSecureValue
        readHighSecureValue
        deleteHighSecureValue
        localStorageAction
    }
}


#Preview {
    LocalStorageTestView()
}
