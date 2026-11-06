//
//  NotificationEventPayload.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The app's canonical `NotificationEvent` payload: a deep link the app opens when the user responds.
struct NotificationEventPayload: Sendable {
    /// The deep link to open; hosts validate it against their own base domain before navigating.
    let applicationUrl: URL
}
