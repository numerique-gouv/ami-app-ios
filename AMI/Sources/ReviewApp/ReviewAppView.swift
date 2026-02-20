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
    @Bindable var viewModel: ReviewAppView.ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Text("Choix de la review")
                .font(.title)
            ScrollView {
                ForEach(reviewApps) { reviewApp in
                    if let reviewAppUrl = URL(string: reviewApp.url) {
                        NavigationLink(value: reviewAppUrl) {
                            Tile(title: reviewApp.title,
                                 content: reviewApp.description ?? "")
                        }
                    }
                }
                .navigationDestination(for: URL.self) { destinationUrl in
                    let viewModel = ReviewAppView.ViewModel.homeViewModel(for: destinationUrl)
                    HomeView(viewModel: viewModel)
                }
            }
            .padding(.top, 1.0)
        }
        // On SwiftUI, removing the defaut Navigation Back button disable the Swipe Back gesture.
        // We reactivate it via trhe underlying UIKit UINavigationController.
        .introspect(.navigationStack, on: .iOS(.v16...)) { view in
            view.interactivePopGestureRecognizer?.isEnabled = true
            view.interactivePopGestureRecognizer?.delegate = nil
        }
        .task {
            Task {
                try await webService.getReviewApps()
                reviewApps.append(contentsOf: webService.reviewApps)
            }
        }
    }
}

#Preview {
    let viewModel = ReviewAppView.ViewModel()
    ReviewAppView(viewModel: viewModel)
        .environmentObject(WebService())
}
