//
//  ReviewAppView.swift
//  AMI
//
//  Created by Aline Bonnet on 05/12/2025.
//

import AmiDesignSystem
import SwiftUI

struct ReviewAppView: View {
    @EnvironmentObject var webService: WebService
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
                    NavigationLink(value: reviewAppUrl) {
                        TileView(title: reviewApp.title,
                                 content: reviewApp.description ?? "")
                    }
                }
            }
            .navigationDestination(for: URL.self) { destinationUrl in
                if let viewModel = viewModel.reviewModel(for: destinationUrl) as? HomeView.ViewModel {
                    HomeView(viewModel: viewModel)
                }
            }
        }
    }
}

#Preview {
    let viewModel = ReviewAppView.ViewModel(rootUrl: Config.shared.BASE_URL, notificationManager: NotificationManager())
    ReviewAppView(viewModel: viewModel)
        .environmentObject(WebService())
}
