//
//  NotificationEventPublisher.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 04/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated protocol NotificationEventPublisher {
    // MARK: Subscribing

    func events() -> AsyncStream<NotificationEvent>

    // MARK: Publishing

    func publish(_ event: NotificationEvent)
    func publishSilentPush(userInfo: [AnyHashable: Any])
}
