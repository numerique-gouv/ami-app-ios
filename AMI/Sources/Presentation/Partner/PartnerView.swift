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
    @Bindable var viewModel: ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    private var webView: AMIWebView {
        AMIWebView(viewModel: viewModel.webViewViewModel)
    }

    @ViewBuilder
    var body: some View {
        webView
            // Show Back button on Partner's view.
            .navigationBarBackButtonHidden(false)
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
