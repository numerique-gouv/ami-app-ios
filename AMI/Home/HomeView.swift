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

    var body: some View {
        VStack {
            if(isExternalProcess){
                BackBar() {
                    webViewRef?.load(URLRequest(url: URL(string: Config.shared.BASE_URL)!))
                }
            }
            WebView(initialURL: Config.shared.BASE_URL, isExternalProcess: $isExternalProcess, webViewRef: $webViewRef)
        }
    }
}

#Preview {
    HomeView()
}
