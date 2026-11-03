//
//  NotificationEventPayload.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The actual meaningfull payload of a `NotificationEvent`.
struct NotificationEventPayload: Sendable {
    let applicationUrl: URL
}
