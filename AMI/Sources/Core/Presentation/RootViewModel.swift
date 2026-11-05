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
final class RootViewModel<T: NotificationEventHandler & Sendable> {
    var presentedViewModel: T

    @ObservationIgnored
    private var observationTask: Task<Void, Never>

    required init(viewModel: T, eventsSource: ObserveNotificationEvents.EventsSource) {
        presentedViewModel = viewModel

        // Local, not a stored property: it is only needed to start the task.
        // The task captures the use case value (not self) → no retain cycle.
        let useCase = ObserveNotificationEvents { event in
            await viewModel.handleReceivedNotificationEvent(event: event)
        }

        observationTask = Self.observationTask(for: useCase, source: eventsSource)
    }

    deinit {
        // Ends the for-await loop, which triggers the stream's onTermination
        // and unsubscribes from the notifications publisher.
        observationTask.cancel()
    }

    private static func observationTask(for useCase: ObserveNotificationEvents, source: ObserveNotificationEvents.EventsSource) -> Task<Void, Never> {
        // Created in a @MainActor init, so the task inherits MainActor isolation.
        Task {
            await useCase.startObserving(source: source)
        }
    }
}
