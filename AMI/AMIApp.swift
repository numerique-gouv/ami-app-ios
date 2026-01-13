//
//  AMIApp.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//

import SwiftUI

@main
struct AMIApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            if Config.shared.CURRENT_ENV == "STAGING" {
                ReviewAppView().environmentObject(WebService())
            } else {
                HomeView()
            }
        }
    }
}
