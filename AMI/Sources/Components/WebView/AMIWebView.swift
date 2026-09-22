//
//  AMIWebView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

struct AMIWebView: View {
    // Make viewModel @Bindable for `fileMover` triggering.
    @Bindable var viewModel: SwiftUIWebView.ViewModel

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

//    @ViewBuilder
//    func backButton(action: (() -> Void)?) -> some View {
//        HStack {
//            Button {
//                action?()
//            } label: {
//                Label(AMIL10n.commonBack, systemImage: "arrowtriangle.left.fill")
//                    .labelStyle(.titleAndIcon) // needed for title to be displayed when located in toolbar.
//                    .fixedSize() // needed for title to be fully displayed.
//            }
//            Spacer()
//        }
//    }

    var body: some View {
        ZStack(alignment: .top) {
            SwiftUIWebView(viewModel: viewModel)
            if viewModel.isLoading {
                loadingBar
                    .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden()
        .fileMover(isPresented: $viewModel.showFileToSaveUI,
                   file: viewModel.fileToSaveSourceURL,
                   onCompletion: { result in
                       viewModel.moveFileDidComplete(sourceUrl: viewModel.fileToSaveSourceURL, result: result)
                   },
                   onCancellation: {
                       viewModel.moveFileCanceled(sourceUrl: viewModel.fileToSaveSourceURL)
                   })
    }
}

extension AMIWebView {
    var canGoBack: Bool {
        viewModel.canGoBack
    }

    func goBack() {
        viewModel.goBack()
    }

    func goBackToInitialUrl() {
        viewModel.goBackToRootUrl()
    }
}

#Preview {
    let viewModel = SwiftUIWebView.ViewModel.default
    AMIWebView(viewModel: viewModel)
}
