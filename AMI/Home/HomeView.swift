//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

struct HomeView: View {
    @State var isExternalProcess = false
    @State var currentURL = Config.shared.BASE_URL
    @State var lastURL = Config.shared.BASE_URL // Not used for now
    
    var body: some View {
        VStack {
            if(isExternalProcess){
                BackBar() {
                    // currentURL = lastURL // Not used for now
                    currentURL = Config.shared.BASE_URL
                }
            }
            WebView(isExternalProcess: $isExternalProcess, currentURL: $currentURL, lastURL: $lastURL)
        }
    }
}

#Preview {
    HomeView()
}
