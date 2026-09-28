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

// MARK: - Event model

/// A Sendable snapshot of a notification. `UNNotification` and `userInfo: [AnyHashable: Any]`
/// are not Sendable, so we copy what we need before crossing concurrency domains.
struct NotificationEvent: Sendable, Identifiable {
    enum Source: Sendable, Equatable {
        /// Notification arrived while the app was in the foreground (willPresent).
        case foreground
        /// The user tapped the notification or one of its actions (didReceive response).
        case userResponse(actionIdentifier: String)
        /// Background / silent push (content-available, no alert).
        case silent
    }

    let id = UUID() // unique per event (same request can produce several events)
    let requestIdentifier: String
    let date: Date
    let title: String
    let body: String
    let categoryIdentifier: String
    let payloadJSON: Data? // full userInfo as JSON, decode it into your own types
    let source: Source

    func decodePayload<T: Decodable>(as type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T? {
        guard let payloadJSON else { return nil }
        return try decoder.decode(T.self, from: payloadJSON)
    }
}

extension NotificationEvent.Source: CustomStringConvertible {
    var description: String {
        switch self {
        case .foreground: "foreground"
        case let .userResponse(actionIdentifier): "userResponse(\"\(actionIdentifier)\""
        case .silent: "silent"
        }
    }
}

extension NotificationEvent {
    /// Define helper `init` in extension to allow automatic `init` to be defined.
    init(request: UNNotificationRequest, date: Date, source: Source) {
        let content = request.content
        self.init(
            requestIdentifier: request.identifier,
            date: date,
            title: content.title,
            body: content.body,
            categoryIdentifier: content.categoryIdentifier,
            payloadJSON: Self.json(from: content.userInfo),
            source: source
        )
    }

    static func json(from userInfo: [AnyHashable: Any]) -> Data? {
        var dict: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? String { dict[key] = value }
        }
        guard JSONSerialization.isValidJSONObject(dict) else { return nil }
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

// MARK: - Hub

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
