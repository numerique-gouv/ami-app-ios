//
//  RootViewModel.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 04/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import SwiftUI

@MainActor
@Observable
final class RootViewModel<T: NotificationEventHandler> {
    var presentedViewModel: T
    private let notificationEventObserver: NotificationEventObserver

    @ObservationIgnored
    private var notificationsObserverTask: Task<Void, Never>

    required init(viewModel: T, eventsSource: NotificationEventObserver.EventsSource) {
        presentedViewModel = viewModel

        notificationEventObserver = NotificationEventObserver { event in
            await viewModel.handleReceivedNotificationEvent(event: event)
        }

        notificationsObserverTask = Self.eventsObservingTask(observer: notificationEventObserver, from: eventsSource)
    }

    deinit {
        // Ends the for-await loop, which triggers the stream's onTermination
        // and unsubscribes from the notifications dispatcher.
        notificationsObserverTask.cancel()
    }

    private static func eventsObservingTask(observer: NotificationEventObserver,
                                            from eventsSource: NotificationEventObserver.EventsSource) -> Task<Void, Never> {
        // Created in a @MainActor init, so the task inherits MainActor isolation.
        // Make a local copy of property `notificationEventObserver` to avoid retain cycle on `self`.
        Task {
            await observer.observeNotifications(from: eventsSource)
        }
    }
}
