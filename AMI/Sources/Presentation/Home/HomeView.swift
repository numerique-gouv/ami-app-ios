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
            Button {
                handleBackAction()
            } label: {
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

    // Temporarily display back button when on OIDC page.
    @ViewBuilder
    private var backButton: some View {
        Button {
            viewModel.webViewViewModel.goBackToRootUrl()
        } label: {
            Label(AMIL10n.amiTitle, systemImage: "arrowtriangle.left.fill")
                .bold()
        }
    }

    @ViewBuilder
    var body: some View {
        // Temporarily display back button when on OIDC page.
        if viewModel.showBackButton {
            backButton
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8.0)
        }
        webView
            .toolbar {
                toolbarBackButton
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView(viewModel: viewModel.settingsViewViewModel)
            }
            .alert(isPresented: $viewModel.showNoEmailClientAlert) {
                Alert(title: Text("Erreur"),
                      message: Text("Aucun client email correctement configuré n'a été trouvé sur votre appareil."),
                      dismissButton: .default(Text("Ok")))
            }
            .sheet(isPresented: $viewModel.isPresentingOnboardingView) {
                OnboardingView(viewModel: viewModel.onboardingViewViewModel)
            }
            .navigationTitle(AMIL10n.amiTitle)
            .navigationBarHidden(true)
            .navigationDestination(item: $viewModel.selectedPartner) { partner in
                switch partner {
                case let .generic(partnerUrl):
                    PartnerView(viewModel: viewModel.partnerModel(for: partnerUrl))
                }
            }
        if viewModel.isOnContactPage {
            Button {
                Task {
                    await viewModel.shareLogs()
                }
            } label: {
                Text("Télécharger les logs")
            }
            .buttonStyle(DsfrButtonStyle(type: .secondary))
            .padding(.vertical)
        }
    }

    private func handleBackAction() {
        if webView.canGoBack {
            webView.goBack()
        } else {
            dismiss()
        }
    }
}

#Preview {
    let viewModel = HomeView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                       websiteDataStore: .nonPersistent(),
                                       notificationManager: NotificationManager())
    HomeView(viewModel: viewModel)
}
