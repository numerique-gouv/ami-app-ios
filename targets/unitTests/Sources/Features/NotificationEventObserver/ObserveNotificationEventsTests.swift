//
//  ObserveNotificationEventsTests.swift
//
//  Use-case tests: forwarding, cancellation, the one-shot source contract,
//  and the "degrading is the handler's call" boundary.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

// Nonisolated suite: the use case and its observing loop really run off the
// main actor in production, so the tests run there too. Events are recorded
// into an `EventRecorder` actor, because the `@Sendable` receive action
// cannot mutate a local var captured by the test under strict concurrency.
@Suite("ObserveNotificationEvents")
nonisolated
struct ObserveNotificationEventsTests {
    @Test func forwardsEachEventInOrder() async {
        let received = EventRecorder<String>()
        let (stream, continuation) = AsyncStream.makeStream(of: NotificationEvent.self, bufferingPolicy: .unbounded)

        let task = Task {
            await ObserveNotificationEvents { event in
                await received.record(event.requestIdentifier)
            }.startObserving(source: stream)
        }

        continuation.yield(makeTestEvent(1))
        continuation.yield(makeTestEvent(2))
        continuation.finish()

        await task.value

        #expect(await received.recorded() == ["req-1", "req-2"])
    }

    // The stream never finishes, so only cancellation can end the loop.
    // `awaitWithin` turns a broken cancellation (which would hang the run)
    // into a recorded failure.
    @Test
    func stopsForwardingWhenTaskIsCancelled() async {
        let received = EventRecorder<String>()
        let (stream, continuation) = AsyncStream.makeStream(of: NotificationEvent.self, bufferingPolicy: .unbounded)

        let task = Task {
            await ObserveNotificationEvents { event in
                await received.record(event.requestIdentifier)
            }.startObserving(source: stream)
        }

        task.cancel()
        _ = await awaitWithin(10) { await task.value }

        continuation.yield(makeTestEvent(1)) // after cancellation: must not be forwarded

        #expect(await received.recorded().isEmpty)
    }

    /// Pins the documented one-shot contract: an `AsyncStream` has a single
    /// consumer, so a second observation of the same source observes nothing.
    @Test func secondObservationOfTheSameSourceIsANoOp() async {
        let received = EventRecorder<String>()
        let (stream, continuation) = AsyncStream.makeStream(of: NotificationEvent.self, bufferingPolicy: .unbounded)
        continuation.yield(makeTestEvent(1))
        continuation.finish()

        let useCase = ObserveNotificationEvents { event in
            await received.record(event.requestIdentifier)
        }
        await useCase.startObserving(source: stream) // consumes the one-shot source
        await useCase.startObserving(source: stream) // source exhausted: nothing happens

        #expect(await received.recorded() == ["req-1"])
    }

    @Test func finishedStreamForwardsNothing() async {
        let received = EventRecorder<String>()
        let (stream, continuation) = AsyncStream.makeStream(of: NotificationEvent.self)
        continuation.finish()

        await ObserveNotificationEvents { event in
            await received.record(event.requestIdentifier)
        }.startObserving(source: stream)

        #expect(await received.recorded().isEmpty)
    }

    // The observer never filters: whether a payload decodes is the handler's
    // `try?` call, not the use case's.
    @Test func undecodablePayloadIsStillForwarded() async throws {
        let received = EventRecorder<NotificationEvent>()
        let garbage = try JSONSerialization.data(withJSONObject: ["not": "the payload shape"])
        let (stream, continuation) = AsyncStream.makeStream(of: NotificationEvent.self)
        continuation.yield(makeTestEvent(1, payloadJSON: garbage))
        continuation.finish()

        await ObserveNotificationEvents { event in
            await received.record(event)
        }.startObserving(source: stream)

        let events = await received.recorded()
        #expect(events.count == 1)
        #expect((try? events[0].decodePayload(as: NotificationEventPayload.self)) == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
