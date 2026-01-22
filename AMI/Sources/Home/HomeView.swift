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
    @State var isOnContactPage = false

    var body: some View {
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
            WebView(initialUrl: Config.shared.BASE_URL, isExternalProcess: $isExternalProcess, isLoading: $isLoading, loadingProgress: $loadingProgress, isOnContactPage: $isOnContactPage)
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
        if isOnContactPage {
            Button {
                handleShareLogsAction()
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
            .animation(.easeInOut, value: isOnContactPage)
        }
    }

    private func handleBackAction() {
        if WebViewManager.shared.webView.canGoBack {
            WebViewManager.shared.webView.goBack()
        } else {
            dismiss()
        }
    }

    private func handleShareLogsAction() {
        Task {
            do {
                let userFcHash = try await WebViewManager.shared.webView.evaluateJavaScript("localStorage.getItem('user_fc_hash')") as? String
                LogsExporter(userId: userFcHash?.trimmingCharacters(in: CharacterSet(charactersIn: "\""))).shareLogs()
            } catch {}
        }
    }
}

#Preview {
    HomeView()
}
