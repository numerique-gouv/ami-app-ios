//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
import WebKit

struct HomeView: View {
    @Environment(\.dismiss) var dismiss
    @State var isExternalProcess = false
    @State var isLoading = false
    @State var loadingProgress: Double = 0.0
    @State var shouldPresentSettings = false

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if isExternalProcess {
                    BackBar {
                        WebViewManager.shared.goHome()
                    }
                }
                if isLoading {
                    ProgressView(value: loadingProgress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }
                WebView(initialUrl: Config.shared.BASE_URL,
                        isExternalProcess: $isExternalProcess,
                        isLoading: $isLoading,
                        loadingProgress: $loadingProgress,
                        shouldPresentSettings: $shouldPresentSettings)
                    .navigationBarBackButtonHidden(true)
                    .toolbar {
                        toolbarBackButton
                    }
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                if gesture.translation.width > 50 {
                                    handleBackAction()
                                }
                            }
                    )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $shouldPresentSettings) {
            SettingsView()
        }
    }

    private func handleBackAction() {
        if WebViewManager.shared.webView.canGoBack {
            WebViewManager.shared.webView.goBack()
        } else {
            dismiss()
        }
    }
}

#Preview {
    HomeView()
}
