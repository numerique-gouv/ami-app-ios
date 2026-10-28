//
//  RootView-ViewModel.swift
//  AMI-Staging
//
//  Created by Nicolas Buquet on 26/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

extension RootView {
    @MainActor
    @Observable
    class ViewModel: NSObject {
        var notificationTriggeredViewModel: HomeView.ViewModel?
    }
}
