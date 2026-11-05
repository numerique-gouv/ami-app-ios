//
//  NotificationEventPublisherDataModule.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 05/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum NotificationEventPublisherDataModule {
    /// Builds the AsyncStream-backed event publisher.
    static func makePublisher() -> any NotificationEventPublisher & Sendable {
        AsyncStreamNotificationEventPublisher()
    }
}
