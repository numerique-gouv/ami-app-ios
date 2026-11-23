//
//  ObserveNotificationEvents.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// The feature's unit of behavior: observes a notification event stream and
/// forwards every event to the host's receive action.
/// Stateless apart from the action — the stream is passed per call, so the
/// instance owns no subscription.
nonisolated struct ObserveNotificationEvents: Sendable {
    /// A subscription to the shared publisher — one per root view model.
    typealias EventsSource = AsyncStream<NotificationEvent>

    private let onReceive: NotificationEventObserverAction

    /// Binds the host's receive action.
    init(onReceive: @escaping NotificationEventObserverAction) {
        self.onReceive = onReceive
    }

    /// Forwards each event of `source` to the action until the calling task is cancelled (e.g. the view's `.task` ends).
    /// Consumes `source`: an `AsyncStream` has a single consumer, so the same source must not be observed twice.
    func startObserving(source: EventsSource) async {
        for await event in source {
            await onReceive(event)
        }
    }
}
