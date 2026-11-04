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
    let id = UUID() // unique per event (same request can produce several events)
    let requestIdentifier: String
    let date: Date
    let title: String
    let body: String
    let categoryIdentifier: String
    let payloadJSON: Data? // full userInfo as JSON, decode it into your own types
    let source: NotificationEventSource

    func decodePayload<T: Decodable>(as type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T? {
        guard let payloadJSON else { return nil }
        return try decoder.decode(T.self, from: payloadJSON)
    }
}
