//
//  SwiftUIWebView.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 13/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI
import WebKit

struct SwiftUIWebView: UIViewRepresentable {
    private let viewModel: SwiftUIWebView.ViewModel

    init(viewModel: SwiftUIWebView.ViewModel) {
        self.viewModel = viewModel
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: viewModel.configuration)
        webView.allowsBackForwardNavigationGestures = viewModel.allowsBackForwardNavigationGestures
        // Give the ViewModel a weak handle on the WKWebView.
        viewModel.webView = webView

        #if DEBUG
            webView.isInspectable = true
        #else
            webView.isInspectable = false
        #endif

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
