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
    /// Define helper `init` in extension to allow automatic `init` to be defined.
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
