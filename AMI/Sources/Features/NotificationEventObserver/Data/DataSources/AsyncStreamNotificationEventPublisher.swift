//
//  AsyncStreamNotificationEventPublisher.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 24/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import os

// MARK: - NotificationEvent Publisher

/// The AsyncStream-backed `NotificationEventPublisher`: one shared bus that
/// broadcasts every published event to all current subscribers, each on its
/// own independent stream.
///
/// `nonisolated` on purpose: `publish` is called from system delegate callbacks
/// that may arrive on any thread. All mutable state lives in `State` behind an
/// `OSAllocatedUnfairLock` — which is why the `Sendable` conformance is `@unchecked`.
final nonisolated class AsyncStreamNotificationEventPublisher: NSObject, @unchecked Sendable {
    /// Internal State to handle multiple subscribers to Notifications.
    private struct State {
        /// Current subscribers, keyed by stream id; removed when the stream terminates.
        var continuations: [UUID: AsyncStream<NotificationEvent>.Continuation] = [:]
        /// Events received while nobody is listening (e.g. cold launch from a tapped
        /// notification, before the view model has subscribed). Replayed to the first subscriber.
        var pending: [NotificationEvent] = []
    }

    /// Use `OSAllocatedUnfairLock` rather than `NSLock` because it is thread safe: you must access inner object through `state.withLock` call.
    /// Useless to use an actor here because we never do async work.
    private let state = OSAllocatedUnfairLock(initialState: State())
    /// Bound for the cold-launch burst (silent push notifications especially); oldest events are dropped first.
    private let maxPending = 20
}

extension AsyncStreamNotificationEventPublisher: NotificationEventPublisher {
    // MARK: Subscribing

    /// A fresh, independent subscription. The first subscriber after a no-subscriber
    /// gap also receives the buffered pending events; a slow subscriber drops its
    /// oldest events (buffer of 50).
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

    /// Delivers the event to every current subscriber, or buffers it in
    /// `State.pending` when nobody is subscribed.
    func publish(_ event: NotificationEvent) {
        let targets: [AsyncStream<NotificationEvent>.Continuation] = state.withLock { state in
            guard !state.continuations.isEmpty else {
                state.pending.append(event)
                if state.pending.count > maxPending {
                    state.pending.removeFirst(state.pending.count - maxPending)
                }
                return []
            }
            return Array(state.continuations.values)
        }
        targets.forEach { $0.yield(event) }
    }

    /// Publishes a silent (background) push from raw `userInfo`, called from the
    /// AppDelegate's `didReceiveRemoteNotification`.
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
