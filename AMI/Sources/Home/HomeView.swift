//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import WebKit

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    @ToolbarContentBuilder
    private var toolbarBackButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: handleBackAction) {
                Label(AMIL10n.commonBack, systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon) // needed for title to be displayed when located in toolbar.
                    .fixedSize() // needed for title to be fully displayed.
            }
            .buttonStyle(.borderless)
            .padding(8.0)
        }
    }

    @ViewBuilder
    private var webView: AMIWebView {
        AMIWebView(viewModel: viewModel.webViewViewModel)
    }

    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isExternalProcess {
                webView.backButton {
                    handleBackAction()
                }
            }
            webView
//            WebViewOld(initialUrl: viewModel.rootUrl,
//                       isExternalProcess: $viewModel.isExternalProcess,
//                       isLoading: $viewModel.isLoading,
//                       loadingProgress: $viewModel.loadingProgress,
//                       isOnContactPage: $viewModel.isOnContactPage,
//                       shouldPresentSettings: $viewModel.shouldPresentSettings)
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    toolbarBackButton
                }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        if viewModel.isOnContactPage {
            Button {
                handleShareLogsAction()
            } label: {
                Text("Télécharger les logs")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Asset.Colors.blueFranceSun113.swiftUIColor)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom))
            .animation(.easeInOut, value: viewModel.isOnContactPage)
        }
    }

    private func handleBackAction() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            dismiss()
        }
    }

    private func handleShareLogsAction() {
        Task {
            do {
                let userFcHash = try await WebViewOldManager.shared.webView.evaluateJavaScript("localStorage.getItem('user_fc_hash')") as? String
                LogsExporter(userId: userFcHash?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))).shareLogs()
            } catch {}
        }
    }
}

#Preview {
    let viewModel = HomeView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!)
    HomeView(viewModel: viewModel)
}
