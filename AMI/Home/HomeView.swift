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
    @State var showNoEmailClientAlert = false
    
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
            WebView(initialUrlString: Config.shared.BASE_URL,
                    isExternalProcess: $isExternalProcess,
                    isLoading: $isLoading,
                    loadingProgress: $loadingProgress,
                    showNoEmailClientAlert: $showNoEmailClientAlert)
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
        .alert(isPresented: $showNoEmailClientAlert) {
            Alert(title: Text("Erreur"),
            message: Text("Aucun client email correctement configuré n'a été trouvé sur votre appareil."),
                  dismissButton: .default(Text("Ok")))
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
