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

/// A single-slot mailbox so a detached work task can hand back its result.
private actor CompletionBox<T: Sendable> {
    private var stored: T?

    func complete(_ value: T) {
        stored = value
    }

    func value() -> T? {
        stored
    }
}

/// Awaits `work` for at most `seconds`: returns the work's result, or
/// `nil` — with a recorded issue — if the deadline elapses first.
/// (Swift Testing in this toolchain has no built-in per-test timeout trait,
/// so this stands in for one.)
///
/// A `withTaskGroup` race cannot enforce this deadline: the scope returns
/// only when **every** child has finished, and `await someTask.value`
/// ignores the awaiter's cancellation — a child awaiting a stuck task would
/// keep the group alive forever, so the "guard" would hang the run. The work
/// therefore runs detached: on timeout it is cancelled and abandoned (a
/// stuck work task may outlive the test; acceptable on the failure path —
/// callers that own the underlying work should cancel it too).
nonisolated func awaitWithin<T: Sendable>(
    _ seconds: Double,
    _ work: @escaping @Sendable () async -> T
) async -> T? {
    let completed = CompletionBox<T>()
    let workTask = Task.detached(priority: .unspecified) { await completed.complete(work()) }
    defer { workTask.cancel() }

    let deadline = ContinuousClock.now + .seconds(seconds)
    while true {
        if let value = await completed.value() {
            return value
        }
        if ContinuousClock.now >= deadline {
            Issue.record("Work did not finish within \(seconds) seconds")
            return nil
        }
        do {
            try await Task.sleep(for: .milliseconds(100))
        } catch {
            return nil // the test task was cancelled: bail without recording
        }
    }
}

// swiftformat:enable all
// swiftlint:enable all
