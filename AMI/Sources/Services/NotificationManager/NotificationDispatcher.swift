//
//  NotificationDispatcher.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 24/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import os
import UserNotifications

// MARK: - Notification Dispatcher

/// Receives notifications from the system and broadcasts them to any number of
/// AsyncStream subscribers. Each call to `events()` returns an independent stream.
///
/// Not MainActor-isolated on purpose: the system may call the delegate off the main thread.
/// If your target uses "Default Actor Isolation = MainActor" (Xcode 26 default for new projects),
/// declare this type `nonisolated final class NotificationDispatcher` (Swift 6.2+).
final class NotificationDispatcher: NSObject, @unchecked Sendable {
    /// Internal State to handle multiple subscribers to Notifications.
    private struct State {
        var continuations: [UUID: AsyncStream<NotificationEvent>.Continuation] = [:]
        /// Events received while nobody is listening (e.g. cold launch from a tapped
        /// notification, before the view model has subscribed). Replayed to the first subscriber.
        var pending: [NotificationEvent] = []
    }

    /// Use `OSAllocatedUnfairLock` rather than `NSLock` because it is thread safe: you must access inner object through `state.withLock` call.
    /// Useless to use an actor here because we never do async work.
    private let state = OSAllocatedUnfairLock(initialState: State())
    private let maxPending = 20

    // MARK: Subscribing

    func events() -> AsyncStream<NotificationEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(50)) { continuation in
            let id = UUID()

            continuation.onTermination = { [weak self] _ in
                self?.state.withLock { $0.continuations[id] = nil }
            }

            let replay: [NotificationEvent] = state.withLock { state in
                state.continuations[id] = continuation
                let pending = state.pending
                state.pending.removeAll()
                return pending
            }
            replay.forEach { continuation.yield($0) }
        }
    }

    // MARK: Publishing

    func publish(_ event: NotificationEvent) {
        let targets: [AsyncStream<NotificationEvent>.Continuation] = state.withLock { state in
            guard !state.continuations.isEmpty else {
                state.pending.append(event)
                if state.pending.count > maxPending { state.pending.removeFirst() }
                return []
            }
            return Array(state.continuations.values)
        }
        targets.forEach { $0.yield(event) }
    }

    /// Call from the AppDelegate's didReceiveRemoteNotification for silent pushes.
    func publishSilentPush(userInfo: [AnyHashable: Any]) {
        let aps = userInfo["aps"] as? [String: Any]
        // Pushes with an alert already reach willPresent / didReceive; skip them to avoid duplicates.
        guard aps?["alert"] == nil else { return }
        publish(NotificationEvent(
            requestIdentifier: UUID().uuidString,
            date: .now,
            title: "",
            body: "",
            categoryIdentifier: aps?["category"] as? String ?? "",
            payloadJSON: NotificationEvent.json(from: userInfo),
            source: .silent
        ))
    }
}
