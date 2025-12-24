//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

struct HomeView: View {
    @State var isExternalProcess = false
    @State var currentURL = BASE_URL
    @State var lastURL = BASE_URL
    
    var body: some View {
        VStack {
            if(isExternalProcess){
                BackBar() {
                    currentURL = lastURL
                }
            }
            WebView(isExternalProcess: $isExternalProcess, currentURL: $currentURL, lastURL: $lastURL)
        }
    }
}

#Preview {
    HomeView()
}
