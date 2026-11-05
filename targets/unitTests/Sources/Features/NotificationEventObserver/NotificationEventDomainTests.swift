//
//  NotificationEventDomainTests.swift
//
//  Domain-layer tests: UN request mapping, payload JSON/decoding guards,
//  and source descriptions.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing
import UserNotifications

@testable import AMI_Staging

// Nonisolated suite: the Domain types are nonisolated `Sendable` value types,
// so the tests can (and do) run off the main actor.
@Suite("NotificationEvent")
nonisolated
struct NotificationEventDomainTests {
    private func makeRequest(title: String = "Title",
                             body: String = "Body",
                             category: String = "CATEGORY",
                             userInfo: [AnyHashable: Any] = [:]) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        content.userInfo = userInfo
        return UNNotificationRequest(identifier: "request-1", content: content, trigger: nil)
    }

    @Test func initFromRequestCopiesAllFields() throws {
        let request = makeRequest(userInfo: ["app_url": "https://numerique.gouv.fr/#/notifications"])

        let event = NotificationEvent(request: request, date: .now, source: .userResponse(actionIdentifier: "default"))

        #expect(event.requestIdentifier == "request-1")
        #expect(event.title == "Title")
        #expect(event.body == "Body")
        #expect(event.categoryIdentifier == "CATEGORY")
        #expect(event.source == .userResponse(actionIdentifier: "default"))
        let payload = try event.decodePayload(as: NotificationEventPayload.self)
        #expect(payload?.applicationUrl.absoluteString == "https://numerique.gouv.fr/#/notifications")
    }

    @Test func nonStringUserInfoKeysAreDropped() {
        let request = makeRequest(userInfo: [42 as NSNumber: "a number key", "app_url": "https://x.fr"])

        let event = NotificationEvent(request: request, date: .now, source: .silent)

        guard let payloadJSON = event.payloadJSON,
              let dict = try? JSONSerialization.jsonObject(with: payloadJSON) as? [String: Any] else {
            Issue.record("Expected a payload JSON holding only the string-keyed entries")
            return
        }
        #expect(dict.count == 1)
        #expect(dict["app_url"] as? String == "https://x.fr")
    }

    @Test func jsonFromNonSerializableUserInfoReturnsNil() {
        // `Date` is not a valid JSON object value: the guard must yield nil, not crash.
        #expect(NotificationEvent.json(from: ["date": Date()]) == nil)
    }

    @Test func decodePayloadReturnsNilWithoutPayload() throws {
        let event = makeTestEvent(1, payloadJSON: nil)

        #expect(try event.decodePayload(as: NotificationEventPayload.self) == nil)
    }

    @Test func decodePayloadThrowsOnMismatchedShape() throws {
        let garbage = try JSONSerialization.data(withJSONObject: ["other": 1])
        let event = makeTestEvent(1, payloadJSON: garbage)

        #expect(throws: DecodingError.self) {
            try event.decodePayload(as: NotificationEventPayload.self)
        }
    }
}

@Suite("NotificationEventPayload")
nonisolated
struct NotificationEventPayloadDecodingTests {
    @Test func decodesAppUrlKey() throws {
        let json = try JSONSerialization.data(withJSONObject: ["app_url": "https://numerique.gouv.fr"])

        let payload = try JSONDecoder().decode(NotificationEventPayload.self, from: json)

        #expect(payload.applicationUrl.absoluteString == "https://numerique.gouv.fr")
    }

    @Test func throwsWhenAppUrlIsMissing() throws {
        let json = try JSONSerialization.data(withJSONObject: ["other": "value"])

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(NotificationEventPayload.self, from: json)
        }
    }

    @Test func throwsWhenAppUrlIsNotAUrl() throws {
        let json = try JSONSerialization.data(withJSONObject: ["app_url": "https://malformed example.com/path with spaces"])

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(NotificationEventPayload.self, from: json)
        }
    }
}

@Suite("NotificationEventSource")
nonisolated
struct NotificationEventSourceTests {
    /// Pins the log format — regression guard for the missing closing paren in `userResponse`.
    @Test func descriptionsPinTheLogFormat() {
        #expect(NotificationEventSource.foreground.description == "foreground")
        #expect(NotificationEventSource.userResponse(actionIdentifier: "action-1").description
            == "userResponse(\"action-1\")")
        #expect(NotificationEventSource.silent.description == "silent")
    }
}

// swiftformat:enable all
// swiftlint:enable all
