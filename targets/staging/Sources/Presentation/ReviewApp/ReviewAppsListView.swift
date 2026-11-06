//
//  ReviewAppsListView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import AmiDesignSystem
import SwiftUI

struct ReviewAppsListView: View {
    @State private var reviewApps: [ReviewApp] = []
    @Bindable var viewModel: ReviewAppsListViewModel

    init(viewModel: ReviewAppsListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Choix de la review")
            .font(DsfrFont.h1.font)
            .foregroundStyle(AmiDesignSystem.Colors.Text.Active.blueFrance.swiftUIColor)
        ScrollView {
            ForEach(viewModel.reviewApps) { reviewApp in
                Button {
                    viewModel.selectReviewApp(reviewApp: reviewApp)
                } label: {
                    TileView(title: reviewApp.title,
                             content: reviewApp.reviewAppDescription ?? "")
                }
            }
        }
        .navigationDestination(item: $viewModel.selectedReviewAppViewModel) { selectedViewModel in
            HomeView(viewModel: selectedViewModel)
        }
        .refreshable {
            Task {
                try? await viewModel.fetchReviewApps()
            }
        }
    }
}

#Preview {
    ReviewAppsListView(viewModel: DependencyContainer.makePreviewReviewAppsListViewModel())
}
