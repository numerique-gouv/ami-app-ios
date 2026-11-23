//
//  NotificationEventJson.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import UserNotifications

extension NotificationEvent {
    /// Maps a `UNNotificationRequest` to a `NotificationEvent`. Lives in Data — the only
    /// layer allowed to import `UserNotifications` — and in an extension, so the
    /// memberwise initializer stays available.
    init(request: UNNotificationRequest, date: Date, source: NotificationEventSource) {
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

    /// Serializes a `userInfo` dictionary to JSON, dropping non-string keys.
    /// Returns `nil` when the result is not a valid JSON object — the event is then delivered without a payload.
    static func json(from userInfo: [AnyHashable: Any]) -> Data? {
        var dict: [String: Any] = [:]
        for (key, value) in userInfo {
            if let key = key as? String { dict[key] = value }
        }
        guard JSONSerialization.isValidJSONObject(dict) else { return nil }
        return try? JSONSerialization.data(withJSONObject: dict)
    }
}

extension NotificationEvent: CustomStringConvertible {
    /// A multi-line, log-ready description: title, body, payload, source.
    var description: String {
        let payloadString = if let jsonData = payloadJSON,
                               let payloadString = String(data: jsonData, encoding: .utf8) {
            payloadString
        } else {
            "<no payload>"
        }

        return """
        \tNotification title: \(title)
        \tNotification body: \(body)
        \tNotification data: \(payloadString)
        \tSource: \(source)
        """
    }
}
