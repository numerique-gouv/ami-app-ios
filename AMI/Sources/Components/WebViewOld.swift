////
////  WebViewOld.swift
////  AMI
////
////  Created by Aline Bonnet on 19/10/2025.
////
//
// import Foundation
// import SwiftUI
// import WebKit
//
// struct WebViewOld: UIViewRepresentable {
//     let initialUrl: URL
//     @Binding var isExternalProcess: Bool
//     @Binding var isLoading: Bool
//     @Binding var loadingProgress: Double
//     @Binding var isOnContactPage: Bool
//     @Binding var shouldPresentSettings: Bool
//
//     func makeUIView(context: Context) -> some UIView {
//         let webView = WebViewOldManager.shared.webView
//         WebViewOldManager.shared.setHome(homeUrl: initialUrl)
//         let contentController = webView.configuration.userContentController
//
//         NativeEvents.attach(contentController, context.coordinator)
//
//         #if DEBUG
//             ConsoleLog.attach(contentController, context.coordinator)
//         #endif
//
//         webView.navigationDelegate = context.coordinator
//         context.coordinator.observeProgress(of: webView)
//         webView.load(URLRequest(url: initialUrl))
//
//         return webView
//     }
//
//     func updateUIView(_ uiView: UIViewType, context: Context) {}
//
//     func makeCoordinator() -> WebViewOldCoordinator {
//         WebViewOldCoordinator(self, isLoading: $isLoading, loadingProgress: $loadingProgress, isOnContactPage: $isOnContactPage)
//     }
// }
