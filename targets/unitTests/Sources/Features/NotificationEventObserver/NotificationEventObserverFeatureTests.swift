//
//  NotificationEventObserverFeatureTests.swift
//
//  End-to-end tests through `NotificationEventObserverFeature`:
//  subscription, cold-launch replay, and the undecodable-payload dark twin.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

// `@MainActor` explicitly: the feature entry point is MainActor-isolated.
@MainActor
@Suite("NotificationEventObserverFeature")
struct NotificationEventObserverFeatureTests {
    private func makeFeature() -> NotificationEventObserverFeature {
        NotificationEventObserverFeature(publisher: NotificationEventPublisherDataModule.makePublisher())
    }

    @Test func makeEventsSourceDeliversPublishedEvents() async {
        let feature = makeFeature()
        let stream = feature.makeEventsSource()
        var iterator = stream.makeAsyncIterator()

        feature.publisher.publish(makeTestEvent(4))

        #expect(await iterator.next()?.requestIdentifier == "req-4")
    }

    // Cold-launch path: the event is published before any source exists and
    // must reach the host action through the whole chain.
    @Test func coldLaunchEventTravelsTheWholeChain() async {
        let feature = makeFeature()
        feature.publisher.publish(makeTestEvent(0)) // no subscriber yet: lands in pending

        let received = EventRecorder<String>()
        let task = Task {
            await ObserveNotificationEvents { event in
                await received.record(event.requestIdentifier)
            }.startObserving(source: feature.makeEventsSource())
        }

        // Wait for the replayed event. Bounded on purpose: a broken chain
        // fails this expectation instead of hanging the run.
        for _ in 0..<100 {
            if !(await received.recorded().isEmpty) { break }
            await Task.yield()
        }
        task.cancel()
        await task.value

        #expect(await received.recorded() == ["req-0"])
    }

    // Dark twin: an undecodable payload must still reach the host action —
    // degrading to "ignore" is the handler's call, not the feature's.
    @Test func undecodablePayloadStillReachesTheHostAction() async throws {
        let feature = makeFeature()
        let garbage = try JSONSerialization.data(withJSONObject: ["unrelated": 1])

        let received = EventRecorder<NotificationEvent>()
        let task = Task {
            await ObserveNotificationEvents { event in
                await received.record(event)
            }.startObserving(source: feature.makeEventsSource())
        }
        feature.publisher.publish(makeTestEvent(0, payloadJSON: garbage))

        for _ in 0..<100 {
            if !(await received.recorded().isEmpty) { break }
            await Task.yield()
        }
        task.cancel()
        await task.value

        let events = await received.recorded()
        #expect(events.count == 1)
        #expect((try? events[0].decodePayload(as: NotificationEventPayload.self)) == nil)
    }
}

// swiftformat:enable all
// swiftlint:enable all
