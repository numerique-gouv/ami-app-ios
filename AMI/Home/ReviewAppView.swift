//
//  ReviewAppView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import SwiftUI

struct ReviewAppView: View {
    @EnvironmentObject var webService: WebService
    @State private var reviewApps = [ReviewApp(url: Config.shared.BASE_URL, title: "Staging", number: 0, description: nil)]
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Choix de la review")
                ForEach(reviewApps, id: \.id) { reviewApp in
                    NavigationLink(destination: HomeView()) {
                        Tile(title: reviewApp.title, content: reviewApp.description ?? "") {
                            Config.shared.BASE_URL = reviewApp.url
                        }
                    }
                }
            }
            .padding(.top, 1)
            .onAppear() {
                Task {
                    try await webService.getReviewApps()
                    reviewApps.append(contentsOf: webService.reviewApps)
                }
            }
        }
    }
}

#Preview {
    ReviewAppView()
}
