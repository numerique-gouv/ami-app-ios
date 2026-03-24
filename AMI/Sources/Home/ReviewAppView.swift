//
//  ReviewAppView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import SwiftUI

struct ReviewAppView: View {
    @EnvironmentObject var webService: WebService
    @State private var reviewApps: [ReviewApp] = []
    @State private var navigate: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Choix de la review")
                ForEach(reviewApps, id: \.id) { reviewApp in
                    if let reviewAppUrl = URL(string: reviewApp.url) {
                        Button {
                            Config.shared.BASE_URL = reviewAppUrl
                            print("ReviewAppView: switching to BASE_URL=\(Config.shared.BASE_URL)")
                            navigate = true
                        } label: {
                            Tile(title: reviewApp.title, content: reviewApp.description ?? "")
                        }
                    }
                }
            }
            .padding(.top, 1)
            .navigationDestination(isPresented: $navigate) {
                HomeView()
            }
            .onAppear {
                Task {
                    try await webService.getReviewApps()
                    reviewApps = webService.reviewApps
                }
            }
        }
    }
}

#Preview {
    ReviewAppView()
}
