//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

struct HomeView: View {
    @State var isExternalProcess = false
    var body: some View {
        VStack {
            if(isExternalProcess){
                BackBar()
            }
            WebView(isExternalProcess: $isExternalProcess)
        }
    }
}

#Preview {
    HomeView()
}
