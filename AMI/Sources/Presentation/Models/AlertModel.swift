//
//  AlertModel.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 16/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct AlertModel: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let okButtonTitle: String?
    let okButtonAction: (() -> Void)?
    let cancelButtonTitle: String

    init(title: String, message: String, okButtonTitle: String? = nil, okButtonAction: (() -> Void)? = nil, cancelButtonTitle: String) {
        self.title = title
        self.message = message
        self.okButtonTitle = okButtonTitle
        self.okButtonAction = okButtonAction
        self.cancelButtonTitle = cancelButtonTitle
    }
}
