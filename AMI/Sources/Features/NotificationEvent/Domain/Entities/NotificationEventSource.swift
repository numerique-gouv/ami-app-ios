//
//  NotificationEventSource.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum NotificationEventSource: Sendable, Equatable {
    /// Notification arrived while the app was in the foreground (willPresent).
    case foreground
    /// The user tapped the notification or one of its actions (didReceive response).
    case userResponse(actionIdentifier: String)
    /// Background / silent push (content-available, no alert).
    case silent
}

extension NotificationEventSource: CustomStringConvertible {
    var description: String {
        switch self {
        case .foreground: "foreground"
        case let .userResponse(actionIdentifier): "userResponse(\"\(actionIdentifier)\""
        case .silent: "silent"
        }
    }
}
