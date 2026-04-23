//
//  PartnerView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import WebKit

struct PartnerView: View {
    @Environment(\.dismiss) var dismiss
    @Bindable var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    private var webView: AMIWebView {
        AMIWebView(viewModel: viewModel.webViewViewModel)
    }

    @ViewBuilder
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            Label(AMIL10n.amiTitle, systemImage: "arrowtriangle.left.fill")
                .bold()
        }
    }

    @ViewBuilder
    var body: some View {
        backButton
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8.0)
        webView
            // Hide Back button on Partner's view.
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $viewModel.showNoEmailClientAlert) {
                Alert(title: Text("Erreur"),
                      message: Text("Aucun client email correctement configuré n'a été trouvé sur votre appareil."),
                      dismissButton: .default(Text("Ok")))
            }
    }
}

#Preview {
    let viewModel = PartnerView.ViewModel(configuration: SwiftUIWebView.sharedConfiguration, rootUrl: URL(string: "https://numerique.gouv.fr")!)
    PartnerView(viewModel: viewModel)
}
