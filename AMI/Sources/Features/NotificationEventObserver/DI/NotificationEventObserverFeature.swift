//
//  NotificationEventObserverFeature.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 05/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Public entry point for the NotificationEventObserver feature.
///
/// Owns the app-wide notification event publisher. The host:
/// - retains this feature for the app's lifetime,
/// - hands `publisher` to the `NotificationManager` at startup:
///
///   ```swift
///   UNUserNotificationCenter.current().delegate = notificationManager
///   // and, from AppDelegate.didReceiveRemoteNotification:
///   notificationManager.publishSilentPush(userInfo: userInfo)
///   ```
///
/// - hands out one `makeEventsSource()` per root view model.
@MainActor
final class NotificationEventObserverFeature {
    /// The shared event publisher. Give it to the host's
    /// `NotificationManager(eventPublisher:)`.
    let publisher: any NotificationEventPublisher & Sendable

    /// Injects the publisher: production passes `NotificationEventPublisherDataModule.makePublisher()`,
    /// tests and previews may pass a fake.
    init(publisher: any NotificationEventPublisher & Sendable) {
        self.publisher = publisher
    }

    /// A fresh observation stream for one root view model. Each call is an
    /// independent subscription; events published before the first
    /// subscription (e.g. cold launch from a tapped notification) are
    /// replayed to that first subscriber.
    func makeEventsSource() -> ObserveNotificationEvents.EventsSource {
        publisher.events()
    }
}
