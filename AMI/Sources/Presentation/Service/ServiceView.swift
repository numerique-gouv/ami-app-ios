//
//  ServiceView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import WebKit

struct ServiceView: View {
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
            viewModel.backToHomeAction?()
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
            .navigationDestination(item: $viewModel.selectedDestination) { destination in
                ServiceView(viewModel: destination.model)
            }
            .task(id: viewModel.webViewViewModel.rootUrl) {
                // Load page now that all is ready.
                viewModel.webViewViewModel.loadInitialPage()
            }
            .sheet(item: $viewModel.receivedContent) { content in
                InfoPanelView(content: content)
            }
    }
}

#Preview {
    ServiceView(viewModel: DependencyContainer.makePreviewServiceViewModel())
}
