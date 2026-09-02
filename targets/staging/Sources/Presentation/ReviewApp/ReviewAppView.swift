//
//  ReviewAppView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import AmiDesignSystem
import SwiftUI

struct ReviewAppView: View {
    @State private var reviewApps: [ReviewApp] = []
    @Bindable var viewModel: ReviewAppView.ViewModel

    init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Choix de la review")
            .font(.title)
        ScrollView {
            ForEach(viewModel.reviewApps) { reviewApp in
                if let reviewAppUrl = URL(string: reviewApp.url) {
                    Button {
                        viewModel.selectReviewApp(reviewApp: reviewApp)
                    } label: {
                        TileView(title: reviewApp.title,
                                 content: reviewApp.description ?? "")
                    }
                }
            }
            .navigationDestination(item: $viewModel.selectedReviewAppViewModel) { viewModel in
                HomeView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    let viewModel = ReviewAppView.ViewModel(websiteDataStore: .nonPersistent(), notificationManager: NotificationManager())
    ReviewAppView(viewModel: viewModel)
}
