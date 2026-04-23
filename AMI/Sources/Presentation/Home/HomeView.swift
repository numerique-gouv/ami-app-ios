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

    @ViewBuilder
    var body: some View {
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
                    PartnerView(viewModel: viewModel.partnerViewModel(for: partnerUrl))
                }
            }
        if viewModel.isOnContactPage {
            Button {
                Task {
                    await viewModel.shareLogs()
                }
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
}

#Preview {
    let viewModel = HomeView.ViewModel(rootUrl: URL(string: "https://numerique.gouv.fr")!,
                                       notificationManager: NotificationManager())
    HomeView(viewModel: viewModel)
}
