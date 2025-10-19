//
//  HomeView.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            WebView(URL(string: BASE_URL)!)
        }
    }
}

#Preview {
    HomeView()
}
