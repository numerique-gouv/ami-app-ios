//
//  NotificationEvent.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

// MARK: - Event model

/// A Sendable snapshot of a notification. `UNNotification` and `userInfo: [AnyHashable: Any]`
/// are not Sendable, so we copy what we need before crossing concurrency domains.
struct NotificationEvent: Sendable, Identifiable {
    /// Unique per delivered event: the same request can produce several (a foreground delivery, then a user response).
    let id = UUID()
    let requestIdentifier: String
    let date: Date
    let title: String
    let body: String
    let categoryIdentifier: String
    /// The full notification `userInfo` as JSON, or `nil` when absent or not JSON-serializable.
    let payloadJSON: Data?
    let source: NotificationEventSource

    /// Decodes `payloadJSON` into a `T`. Returns `nil` when the event carries no payload,
    /// throws when it does not match `T` — handlers treat both as "no payload" via `try?`.
    func decodePayload<T: Decodable>(as type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T? {
        guard let payloadJSON else { return nil }
        return try decoder.decode(T.self, from: payloadJSON)
    }
}
