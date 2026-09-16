//
//  WebViewAlertModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 16/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct WebViewAlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let closeButtonTitle: String
}
