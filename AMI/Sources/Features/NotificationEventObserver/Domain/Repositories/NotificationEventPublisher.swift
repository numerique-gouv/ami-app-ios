//
//  NotificationEventPublisher.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 04/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The feature's event bus: producers publish `NotificationEvent`s, consumers
/// subscribe to independent streams.
///
/// `nonisolated` because producers are system delegate callbacks that may
/// arrive off the main thread. Portability is declared at each crossing
/// boundary (`any NotificationEventPublisher & Sendable`), not on this role.
nonisolated protocol NotificationEventPublisher {
    // MARK: Subscribing

    /// A fresh, independent subscription; the first subscriber after a
    /// no-subscriber gap also receives the events buffered in the meantime.
    func events() -> AsyncStream<NotificationEvent>

    // MARK: Publishing

    /// Publishes an event to every current subscriber, or buffers it for the
    /// first subscriber when nobody is listening.
    func publish(_ event: NotificationEvent)

    /// Publishes a silent (background) push from raw `userInfo`. Payloads
    /// carrying an alert are skipped — they already arrive via the notification delegate.
    func publishSilentPush(userInfo: [AnyHashable: Any])
}
