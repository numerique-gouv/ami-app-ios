//
//  AMIWebView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct AMIWebView: View {
    let viewModel: SwiftUIWebView.ViewModel

    @ViewBuilder
    var loadingBar: some View {
        ProgressView(value: viewModel.estimatedProgress)
            .progressViewStyle(.linear)
            .tint(.blue)
    }

    @ViewBuilder
    var webView: SwiftUIWebView {
        SwiftUIWebView(viewModel: viewModel)
    }

    var body: some View {
        if viewModel.isLoading {
            loadingBar
        }
        SwiftUIWebView(viewModel: viewModel)
    }
}

extension AMIWebView {
    var canGoBack: Bool {
        viewModel.canGoBack
    }

    func goBack() {
        viewModel.goBack()
    }
}

#Preview {
    let viewModel = SwiftUIWebView.ViewModel.default
    AMIWebView(viewModel: viewModel)
}
