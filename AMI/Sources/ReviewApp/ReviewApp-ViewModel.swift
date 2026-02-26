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
        private var viewModels = [URL: AnyObject]()
        
        func reviewModel(for url: URL) -> AnyObject {
            guard let viewModel = viewModels[url] else {
                let viewModel = HomeView.ViewModel(rootUrl: url)
                viewModels[url] = viewModel
                return viewModel
            }
            return viewModel
        }

        deinit {
            print("deinit")
        }
    }
}
