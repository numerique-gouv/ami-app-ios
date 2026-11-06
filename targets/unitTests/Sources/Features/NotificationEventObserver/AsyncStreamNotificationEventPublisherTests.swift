//
//  AsyncStreamNotificationEventPublisherTests.swift
//
//  Data-layer tests: broadcast, cold-launch replay, pending eviction,
//  silent-push duplicate guard, concurrent publishing.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

// Nonisolated suite: `publish` really arrives off the main thread from system
// delegate callbacks, so exercising the publisher off-main is the production
// path. No `@Sendable` mutable captures — consumption happens in the test
// body through the stream's iterator.
@Suite("AsyncStreamNotificationEventPublisher")
nonisolated
struct AsyncStreamNotificationEventPublisherTests {
    @Test func publishWithNoSubscriberIsReplayedToFirstSubscriber() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        publisher.publish(makeTestEvent(0)) // cold: lands in pending

        let stream = publisher.events()
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next()?.requestIdentifier == "req-0")
    }

    @Test func pendingIsReplayedOnlyToTheFirstSubscriber() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        publisher.publish(makeTestEvent(0)) // cold: lands in pending
        let first = publisher.events()
        let second = publisher.events()
        publisher.publish(makeTestEvent(1)) // live: both receive it
        var firstIterator = first.makeAsyncIterator()
        var secondIterator = second.makeAsyncIterator()

        #expect(await firstIterator.next()?.requestIdentifier == "req-0")  // drained the pending
        #expect(await firstIterator.next()?.requestIdentifier == "req-1")
        #expect(await secondIterator.next()?.requestIdentifier == "req-1") // second never saw req-0
    }

    @Test func twoLiveSubscribersBothReceiveEvents() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        let first = publisher.events()
        let second = publisher.events()
        var firstIterator = first.makeAsyncIterator()
        var secondIterator = second.makeAsyncIterator()

        publisher.publish(makeTestEvent(7))

        #expect(await firstIterator.next()?.requestIdentifier == "req-7")
        #expect(await secondIterator.next()?.requestIdentifier == "req-7")
    }

    /// Accepted limitation: at most 20 events are kept before any subscriber
    /// exists; the oldest ones are dropped first.
    @Test func evictionKeepsTheNewestTwentyPendingEvents() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        for index in 0..<25 {
            publisher.publish(makeTestEvent(index))
        }

        let stream = publisher.events()
        var iterator = stream.makeAsyncIterator()

        #expect(await iterator.next()?.requestIdentifier == "req-5") // req-0…req-4 dropped
        var last: String?
        for _ in 0..<19 {
            last = await iterator.next()?.requestIdentifier
        }
        #expect(last == "req-24")
    }

    // Cancellation terminates the stream, and awaiting the consumer's value
    // guarantees the publisher's `onTermination` — its unregistration — completed.
    @Test func terminatedSubscriberDoesNotStarvePendingReplay() async {
        let publisher = AsyncStreamNotificationEventPublisher()

        let shortLived = publisher.events()
        let consumer = Task {
            let stream = shortLived // copy sharing the same subscription
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }
        consumer.cancel()
        _ = await consumer.value

        publisher.publish(makeTestEvent(9)) // nobody listening: lands in pending

        let stream = publisher.events()
        var iterator = stream.makeAsyncIterator()
        #expect(await iterator.next()?.requestIdentifier == "req-9") // replayed: old continuation is gone
    }

    /// An alert-carrying push already arrives through `willPresent`/`didReceive`;
    /// publishing it again would be a duplicate.
    @Test func silentPushWithAlertIsSkipped() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        let stream = publisher.events()
        var iterator = stream.makeAsyncIterator()

        publisher.publishSilentPush(userInfo: ["aps": ["alert": "Hello"], "app_url": "https://x.fr"])

        // Prove nothing was published: the next live event must be the stream's first delivery.
        publisher.publish(makeTestEvent(3))
        #expect(await iterator.next()?.requestIdentifier == "req-3")
    }

    @Test func silentPushWithoutAlertIsDeliveredAsSilentEvent() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        let stream = publisher.events()
        var iterator = stream.makeAsyncIterator()

        publisher.publishSilentPush(userInfo: [
            "aps": ["category": "SILENT_CATEGORY"],
            "app_url": "https://numerique.gouv.fr/#/notifications",
        ])

        guard let event = await iterator.next() else {
            Issue.record("Expected a silent event")
            return
        }
        #expect(event.source == .silent)
        #expect(event.title.isEmpty)
        #expect(event.body.isEmpty)
        #expect(event.categoryIdentifier == "SILENT_CATEGORY")
        #expect(!event.requestIdentifier.isEmpty)
        let payload = try? event.decodePayload(as: NotificationEventPayload.self)
        #expect(payload?.applicationUrl.absoluteString == "https://numerique.gouv.fr/#/notifications")
    }

    /// Guards the `OSAllocatedUnfairLock` state: four concurrent publishers
    /// race through `publish` while one consumer counts.
    ///
    /// The total (48) deliberately stays under the stream's buffer (50):
    /// even a consumer that starts only after every publish still receives
    /// all 48 from the buffer, so no drop is *possible* — "lossless" is
    /// pinned by the buffer invariant, not by the consumer winning a
    /// scheduling race (200 against a 50-slot buffer lost that race on
    /// cold runs and hung the run for good).
    @Test
    func concurrentPublishingIsLossless() async {
        let publisher = AsyncStreamNotificationEventPublisher()
        let total = 48
        let stream = publisher.events()

        let received = Task {
            var count = 0
            for await _ in stream {
                count += 1
                if count == total { break }
            }
            return count
        }

        await withTaskGroup(of: Void.self) { group in
            for taskIndex in 0..<4 {
                group.addTask {
                    for index in 0..<12 {
                        publisher.publish(makeTestEvent(taskIndex * 12 + index))
                        await Task.yield()
                    }
                }
            }
        }

        let count: Int? = await awaitWithin(30) { await received.value }
        received.cancel() // on the (failing) timeout path: ends the consumer and the abandoned work
        #expect(count == total)
    }
}

// swiftformat:enable all
// swiftlint:enable all
