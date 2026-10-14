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
//                Label(AMIL10n.Main.commonBack, systemImage: "arrowtriangle.left.fill")
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
        .alert(item: $viewModel.alertModel) { alert in
            if let okTitle = alert.okButtonTitle,
               let okAction = alert.okButtonAction {
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      primaryButton: .default(Text(okTitle), action: okAction),
                      secondaryButton: .default(Text(alert.cancelButtonTitle)))
            } else {
                Alert(title: Text(alert.title),
                      message: Text(alert.message),
                      dismissButton: .default(Text(alert.cancelButtonTitle)))
            }
        }
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
    AMIWebView(viewModel: DependencyContainer.makeSimulatorPreviewSwiftUIWebViewModel())
}
