//
//  ObserveNotificationEvents.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

nonisolated struct ObserveNotificationEvents: Sendable {
    typealias EventsSource = AsyncStream<NotificationEvent>

    private let onReceive: NotificationEventObserverAction

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
