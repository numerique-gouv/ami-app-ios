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
            .font(DsfrFont.h1.font)
            .foregroundStyle(AmiDesignSystem.Colors.Text.Active.blueFrance.swiftUIColor)
        ScrollView {
            ForEach(viewModel.reviewApps) { reviewApp in
                if URL(string: reviewApp.url) != nil {
                    Button {
                        viewModel.selectReviewApp(reviewApp: reviewApp)
                    } label: {
                        TileView(title: reviewApp.title,
                                 content: reviewApp.reviewAppDescription ?? "")
                    }
                }
            }
            .navigationDestination(item: $viewModel.selectedReviewAppViewModel) { viewModel in
                HomeView(viewModel: viewModel)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pendingUrl)) { notification in
            viewModel.notificationReceived(notification: notification)
        }
        .refreshable {
    }
}

#Preview {
    ReviewAppView(viewModel: DependencyContainer.makePreviewReviewAppViewModel())
}
