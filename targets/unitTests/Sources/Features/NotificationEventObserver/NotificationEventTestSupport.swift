//
//  NotificationEventTestSupport.swift
//
//  Shared test factory for the NotificationEventObserver feature tests.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

/// A `NotificationEvent` with a predictable `requestIdentifier` (`"req-<index>"`),
/// so ordering and count assertions can identify events by index.
///
/// `nonisolated` on purpose: under the default `MainActor` isolation a plain
/// global function would be MainActor-isolated and unreachable from the
/// nonisolated suites.
nonisolated func makeTestEvent(_ index: Int,
                               payloadJSON: Data? = nil,
                               source: NotificationEventSource = .foreground) -> NotificationEvent {
    NotificationEvent(requestIdentifier: "req-\(index)",
                      date: .now,
                      title: "Title \(index)",
                      body: "Body \(index)",
                      categoryIdentifier: "CATEGORY",
                      payloadJSON: payloadJSON,
                      source: source)
}

/// Records values from any isolation domain.
///
/// The receive action passed to `ObserveNotificationEvents` is `@Sendable`
/// and runs off the main actor, so it cannot mutate a plain local `var`
/// captured by the test ("mutation of captured var in concurrently-executing
/// code"). Recording into this actor instead is legal from any isolation.
actor EventRecorder<T: Sendable> {
    private var values: [T] = []

    func record(_ value: T) {
        values.append(value)
    }

    func recorded() -> [T] {
        values
    }
}

/// Awaits `work`, but records an issue — instead of hanging the test run —
/// if it does not finish within `seconds`. Returns the work's result, or
/// `nil` on timeout. (Swift Testing in this toolchain has no built-in
/// per-test timeout trait, so this stands in for one.)
nonisolated func awaitWithin<T: Sendable>(
    _ seconds: Double,
    _ work: @escaping @Sendable () async -> T
) async -> T? {
    let result: T? = await withTaskGroup(of: T?.self) { group -> T? in
        group.addTask { await work() }
        group.addTask {
            _ = try? await Task.sleep(for: .seconds(seconds))
            return nil
        }
        let finished: T? = await group.next().flatMap { $0 }
        group.cancelAll()
        return finished
    }
    if result == nil {
        Issue.record("Work did not finish within \(seconds) seconds")
    }
    return result
}

// swiftformat:enable all
// swiftlint:enable all
