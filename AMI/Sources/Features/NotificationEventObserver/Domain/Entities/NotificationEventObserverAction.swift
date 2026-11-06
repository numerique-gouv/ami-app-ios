//
//  NotificationEventObserverAction.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The host's receive seam: invoked once per delivered `NotificationEvent` by `ObserveNotificationEvents`.
/// `@Sendable` because the observing loop runs off the main actor — the host hops back to its own isolation when needed.
typealias NotificationEventObserverAction = @Sendable (NotificationEvent) async -> Void
