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
    @State var currentURL = Config.shared.BASE_URL
    @State var lastURL = Config.shared.BASE_URL // Not used for now
    @State var webViewRef: WKWebView? = nil

    var body: some View {
        VStack {
            if(isExternalProcess){
                BackBar() {
                    // currentURL = lastURL // Not used for now
                    currentURL = Config.shared.BASE_URL
                }
            }
            WebView(isExternalProcess: $isExternalProcess, currentURL: $currentURL, lastURL: $lastURL, webViewRef: $webViewRef)
        }
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

    private func handleBackAction() {
        if let webView = webViewRef, webView.canGoBack {
            webView.goBack()
        } else {
            dismiss()
        }
    }
}

#Preview {
    HomeView()
}
