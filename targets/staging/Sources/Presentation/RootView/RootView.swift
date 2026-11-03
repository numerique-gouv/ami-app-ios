//
//  RootView.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 26/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import SwiftUI

struct RootView: View {
    @Bindable var viewModel: ViewModel

    @ViewBuilder
    var body: some View {
        if let notificationTriggeredViewModel = viewModel.notificationTriggeredViewModel {
            HomeView(viewModel: notificationTriggeredViewModel)
        } else {
            ReviewAppView(viewModel: DependencyContainer.makeReviewAppsListViewModel())
        }
    }
}
