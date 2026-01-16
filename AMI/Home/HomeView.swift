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

    var body: some View {
        VStack(spacing: 0) {
            if(isExternalProcess){
                BackBar() {
                    WebViewManager.shared.goHome()
                }
            }
            if isLoading {
                ProgressView(value: loadingProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            WebView(initialUrlString: Config.shared.BASE_URL, isExternalProcess: $isExternalProcess, isLoading: $isLoading, loadingProgress: $loadingProgress)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleBackAction) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Retour")
                        }
                    }
                }
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
