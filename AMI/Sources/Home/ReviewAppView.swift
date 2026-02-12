//
//  ReviewAppView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct ReviewAppView: View {
    @EnvironmentObject var webService: WebService
    @State private var reviewApps: [ReviewApp] = []

    var body: some View {
        NavigationView {
            ScrollView {
                Text("Choix de la review")
                ForEach(reviewApps, id: \.id) { reviewApp in
                    if let reviewAppUrl = URL(string: reviewApp.url) {
                        NavigationLink(destination: HomeView()) {
                            Tile(title: reviewApp.title, content: reviewApp.description ?? "") {
                                Config.shared.BASE_URL = reviewAppUrl
                            }
                        }
                    }
                }
            }
            .padding(.top, 1)
            .onAppear {
                Task {
                    try await webService.getReviewApps()
                    reviewApps.append(contentsOf: webService.reviewApps)
                }
            }
        // On SwiftUI, removing the defaut Navigation Back button disable the Swipe Back gesture.
        // We reactivate it via trhe underlying UIKit UINavigationController.
        .introspect(.navigationStack, on: .iOS(.v16...)) {
            $0.interactivePopGestureRecognizer?.isEnabled = true
            $0.interactivePopGestureRecognizer?.delegate = nil
        }
        }
    }
}

#Preview {
    ReviewAppView()
}
