# NotificationEventObserver

Turns system notifications (foreground, user tap, silent push) into
`Sendable` `NotificationEvent`s delivered to the app's root view model,
including events that arrive before the UI exists (cold launch).

## How it works

1. The host's `NotificationManager` (UN delegate + FCM) publishes each
   notification to the shared publisher.
2. The publisher broadcasts each event to all live subscribers, each on
   an independent stream; events published while nobody is subscribed are
   buffered and replayed to the first subscriber.
3. `RootViewModel` (Core) takes a stream from `makeEventsSource()` and
   runs `ObserveNotificationEvents` until deinit cancels it; the use case
   forwards every event to the host's receive action.
4. The host view model filters on `event.source` and decodes the payload
   with `try?` — failure means "ignore the event".

## Layers

- **Domain** — `NotificationEvent` (+ `Source`, `Payload`, `EventHandler`), the
  `NotificationEventPublisher` role and the `ObserveNotificationEvents` use case. No framework imports, all `nonisolated`.
- **Data** — the AsyncStream-backed publisher, `app_url` wire decoding, and the
  data module that alone knows the concrete type.
- **DI** — `NotificationEventObserverFeature`: the sole public entry point.

## Usage

```swift
// DependencyContainer (app lifetime)
static let notificationEventObserverFeature = NotificationEventObserverFeature(
    publisher: NotificationEventPublisherDataModule.makePublisher())
static let notificationManager = NotificationManager(
    eventPublisher: notificationEventObserverFeature.publisher)
UNUserNotificationCenter.current().delegate = notificationManager
// AppDelegate.didReceiveRemoteNotification:
notificationManager.publishSilentPush(userInfo: userInfo)
// per root view model (makeRootViewModel)
RootViewModel(viewModel: homeViewModel,
              eventsSource: notificationEventObserverFeature.makeEventsSource())
```

## Contract

- Host owns delegate setup and silent-push forwarding; the feature only transports (one source per root view model).
- No filtering in the feature: undecodable payloads still reach the host; degrading to "do nothing" is the handler's `try?` call.
- Accepted limits: while nobody is subscribed, at most the 20 newest events are kept (oldest dropped first) and replayed once to the first subscriber; a lagging subscriber drops the oldest of its own stream (buffer of 50); alert pushes are not re-published.
- DI = the app-level `DependencyContainer` + this entry; tests inject a fake publisher via the feature's init.
