//
//  NotificationEventHandler.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 04/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// A view model that reacts to delivered notification events.
///
/// Host contract: one request can deliver several events (foreground, then user
/// response), so filter on `event.source` — in practice only `.userResponse`
/// drives navigation — and decode the payload with `try?` so a missing or
/// malformed payload means "do nothing". Conformers are typically `@MainActor`
/// view models; boundary callers add `& Sendable` when capturing one.
nonisolated protocol NotificationEventHandler {
    /// Called once per delivered event.
    func handleReceivedNotificationEvent(event: NotificationEvent) async
}
