//
//  NotificationEventObserver.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

struct NotificationEventObserver {
    typealias EventsSource = AsyncStream<NotificationEvent>

    private let notificationObserverAction: NotificationEventObserverAction

    init(notificationObserverAction: @escaping NotificationEventObserverAction) {
        self.notificationObserverAction = notificationObserverAction
    }

    /// Runs until the calling task is cancelled (e.g. the view's `.task` ends).
    func observeNotifications(from eventsSource: EventsSource) async {
        for await event in eventsSource {
            await handleIncomingNotification(event)
        }
    }

    /// The method called when a notification event is received.
    /// Notification event contains the application URL in its payload (see `NotificationEventPayload`).
    /// The notification is ignored if its payload application URL domain doesn't match the current base domain.
    private func handleIncomingNotification(_ event: NotificationEvent) async {
        switch event.source {
        case .foreground:
            break // e.g. refresh data
        case let .userResponse(action):
            _ = action // e.g. deep link / navigate
        case .silent:
            break // e.g. sync in background
        }

        AppLog.viewModel.notice(
            """
            \(AppLog.logHeader(self)) ViewModel received notification:
            \(event)
            """
        )

        // Dispatch Notification event.
        await notificationObserverAction(event)
    }
}
