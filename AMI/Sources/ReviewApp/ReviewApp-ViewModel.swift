//
//  ReviewApp-ViewModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 20/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

extension ReviewAppView {
    @Observable
    class ViewModel: NSObject {
//        private var currentViewModel: HomeView.ViewModel?
        
        static func homeViewModel(for url: URL) -> HomeView.ViewModel {
            HomeView.ViewModel(rootUrl: url)
        }
        
        deinit {
            print("deinit")
        }
    }
}

