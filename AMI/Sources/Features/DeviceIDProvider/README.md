# DeviceIDProvider Feature

Manages the application's device identifier: a unique value identifying this installation on the current device, which the backend correlates with the user account to maintain per-device state — notably push-notification consent. It also invalidates the identifier after app reinstall so the consent flow is re-proposed.

## How it works

1. `DeviceIDProvider` (Domain port) exposes `getOrCreateDeviceID()` and `resetDeviceID(onReset:)`; the identifier is a `DeviceID` (String, UUID).
2. `LocalStorageDeviceIDProvider` (Data actor) persists the ID in `.encrypted` storage (Keychain, **survives uninstallation**) and keeps the first-launch flag in `.private` storage (UserDefaults, does not survive).
3. `getOrCreateDeviceID()` returns the stored ID; when missing or unreadable it generates a UUID and persists it; when storage is unavailable it serves a cached in-memory (ephemeral) ID, stable within the process.
4. `resetDeviceID(onReset:)` invalidates the stored ID — the replacement is deferred to the next `getOrCreateDeviceID()`; the async `onReset` action is invoked when the fresh ID is persisted: at most once, possibly never, last call wins.
5. `cleanUpAtFirstLaunch()` (bootstrap-only) detects the first launch since (re)install from the step-2 storage asymmetry and requests a reset; the flag is written only from the reset completion, so an uncompleted reset re-runs at the next launch.

## Layers

- `Domain/` entity `DeviceID` + port `DeviceIDProvider`
- `Data/` actor `LocalStorageDeviceIDProvider`

The app `DependencyContainer` owns the single instance; hermetic tests in `targets/unitTests/DeviceIDProviderTests`.

## Usage

```swift
// Composition root — single instance per process:
static let deviceIdProvider = LocalStorageDeviceIDProvider()

// App bootstrap — before any getOrCreateDeviceID():
Task { await deviceIdProvider.cleanUpAtFirstLaunch() }

// Consumers (API headers, device registration…):
let deviceID = await deviceIdProvider.getOrCreateDeviceID()
```

## Contract

- **One instance per process**: the provider holds in-memory state (pending reset flag, cached ephemeral ID); only the composition root constructs it.
- `cleanUpAtFirstLaunch()` is a concrete-type API (not on the port) and runs at bootstrap; the deferred `Task` is safe because device registration only happens after login.
- The first-launch flag is written **only when the reset completes**: if the Keychain write cannot succeed (locked device, no passcode), the flag stays absent and the cleanup retries at the next launch.
- While storage is unavailable, `getOrCreateDeviceID()` may return an **ephemeral** ID (stable in-process, changes across launches); consumers must tolerate it.
