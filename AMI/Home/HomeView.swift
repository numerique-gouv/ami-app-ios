//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI
import WebKit

struct HomeView: View {
    @State var isExternalProcess = false
    @State var webViewRef: WKWebView?
    @State var isLoading = false
    @State var loadingProgress: Double = 0.0

    var body: some View {
        VStack(spacing: 0) {
            if(isExternalProcess){
                BackBar() {
                    webViewRef?.load(URLRequest(url: URL(string: Config.shared.BASE_URL)!))
                }
            }
            if isLoading {
                ProgressView(value: loadingProgress)
                    .progressViewStyle(.linear)
                    .tint(.blue)
            }
            WebView(initialURL: Config.shared.BASE_URL, isExternalProcess: $isExternalProcess, webViewRef: $webViewRef, isLoading: $isLoading, loadingProgress: $loadingProgress)
        }
    }
}

#Preview {
    HomeView()
}
