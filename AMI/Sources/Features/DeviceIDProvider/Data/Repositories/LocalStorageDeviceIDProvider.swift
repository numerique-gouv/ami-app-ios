//
//  LocalStorageDeviceIDProvider.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/08/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// DeviceIDProvider implementation backed by LocalStorageRepository:
/// - the ID in .encrypted storage (Keychain)
/// - the first-launch flag in .private storage (UserDefaults)
///
/// - Note: This type holds in-memory state (pending reset flag, cached
///   ephemeral ID) and must be used as a single shared instance per process.
///   The composition root owns that instance.
final actor LocalStorageDeviceIDProvider {
    /// The factory method to create the LocalStorageRepository
    typealias StorageFactory = @Sendable (String) -> any LocalStorageRepositoryProtocol

    // The name of the LocalStorage to store device id.
    private static let DEVICE_ID_LOCAL_STORAGE_NAME = "applicationData"
    // The key used to store `device id` in the LocalStorage.
    private static let DEVICE_ID_KEY = "deviceID"
    // The key used to store the first launch flag in LocalStorage.
    private static let APPLICATION_HAS_LAUNCHED_BEFORE_KEY = "applicationHasLaunchedBefore"

    /// A flag indicating a device ID reset is pending.
    /// Its role is to avoid reusing an invalidated device ID.
    /// While the invalidated device ID can't be reset, a cached device ID will be served.
    private var resetCurrent = false

    /// Action called once the device ID is really reset.
    private var resetCurrentPostAction: DeviceIDProvider.ResetDeviceIDCompletionAction?

    /// The cached Device ID property (used only if deviceID can't be stored in storage repository
    /// or when the current device ID is invalidated).
    /// This is to avoid generating a new device ID on each call when storage repository is not usable.
    private var cachedDeviceID: DeviceID?

    /// Dependency injection properties to know how to access local storage used to store device ID.
    private let localStorageName: String
    private let makeStorage: StorageFactory

    /// - Parameters:
    ///   - localStorageName: Name of the LocalStorage used to persist the device ID.
    ///   - makeStorage: Factory for the storage repository. Injectable for testing.
    init(localStorageName: String = DEVICE_ID_LOCAL_STORAGE_NAME, makeStorage: @escaping StorageFactory = { LocalStorageRepository(for: $0) }) {
        self.localStorageName = localStorageName
        self.makeStorage = makeStorage
    }

    /// Invalidates the stored device ID on the first launch since (re)installation.
    ///
    /// Detection relies on the asymmetry between the two storage levels:
    /// - the device ID lives in `.encrypted` storage (Keychain), which
    ///   **survives** app uninstallation;
    /// - the first-launch flag used here lives in `.private` storage
    ///   (UserDefaults), which **does not** survive it.
    ///
    /// Behavior:
    /// 1. **Flag present** — a regular launch. Nothing is done.
    /// 2. **Flag absent** — first launch, either a genuine first install or a
    ///    reinstall. The stored device ID (if any) is invalidated through
    ///    `resetDeviceID(onReset:)`: the next `getOrCreateDeviceID()` call
    ///    generates and persists a fresh ID, breaking the backend's link to the
    ///    previous installation's push-notification consent state, so the
    ///    consent flow is re-proposed. On a genuine first install no ID is
    ///    stored yet, so the reset is a no-op.
    ///
    /// The flag is written **only from the reset completion**, i.e. only once
    /// the fresh device ID has actually been persisted. If persistence is not
    /// possible yet (e.g. device locked) or the app terminates first, the flag
    /// stays absent and this method simply runs again at the next launch — the
    /// reset is retried until it completes.
    ///
    /// - Note: Call this once at application bootstrap, **before any
    ///   `getOrCreateDeviceID()` call**: a read performed before the reset is
    ///   requested could still serve the pre-reinstall ID for that one call.
    /// - Note: This method only requests the reset; the actual device ID
    ///   replacement is deferred to the next `getOrCreateDeviceID()` call.
    func cleanUpAtFirstLaunch() async {
        let storage = makeStorage(localStorageName)

        switch await storage.readBool(key: Self.APPLICATION_HAS_LAUNCHED_BEFORE_KEY, secureLevel: .private) {
        case .success:
            // The flag value already exists: this is not a first launch.
            // No need to reset any stored deviceID.
            break
        case .failure(.keyNotFound), .failure(.typeMismatch):
            // Key absent, or flag corrupted: first-launch treatment.
            // Any previous stored deviceID need to be deleted.
            await resetDeviceID {
                // Don't read the result: we can't do anything if write fails.
                _ = await storage.writeBool(key: Self.APPLICATION_HAS_LAUNCHED_BEFORE_KEY, value: true, secureLevel: .private)
            }
        case let .failure(error):
            // Can't tell whether this is a first launch: skip the reset
            // rather than rotating a returning user's ID.
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to read first-launch flag: \(error)")
        }
    }

    /// Creates a new device ID and attempts to store it persistently.
    ///
    /// - Parameter storage: The storage repository to use for persistence
    /// - Returns: A new device ID (either persisted or ephemeral but cached)
    ///
    /// - Note: If, for any reason, the newly generated device ID can't be stored in storage repository, the device ID is ephemeral.
    ///   If no ephemeral cached device ID already exists, store the newly generated device ID as the actual cached ID;
    ///   Then, returns the actual cached ID.
    private func createAndStoreNewDeviceID(using storage: any LocalStorageRepositoryProtocol) async -> DeviceID {
        // Use existing cached device ID if it is already created.
        // This reinforces the cached device ID stability: don't create any new device ID if cached one exists.
        let newDeviceID: DeviceID = cachedDeviceID ?? UUID().uuidString

        // Set ephemeral ID to `cachedDeviceID` in case a concurrent `createAndStoreNewDeviceID` is called.
        // Although `LocalStorageDeviceIDProvider` is an actor, there is a suspension point during next `await storage.writeString()`
        // that allows concurrent execution of another `createAndStoreNewDeviceID` call.
        cachedDeviceID = newDeviceID

        switch await storage.writeString(key: Self.DEVICE_ID_KEY, value: newDeviceID, secureLevel: .encrypted) {
        case .success:
            AppLog.service.notice("\(AppLog.logHeader(self)) ✅ New device ID successfully stored: \(newDeviceID, privacy: .private)")
            // Always set `resetCurrent` to false when a newly created device ID is successfully stored.
            if resetCurrent {
                // Call optional `resetCurrentPostAction` only if `resetCurrent` is `true`.
                resetCurrent = false
                await resetCurrentPostAction?()
                resetCurrentPostAction = nil
            }
            return newDeviceID

        case let .failure(error):
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to persist new device ID: \(error).\nUsing cached device ID: \(newDeviceID, privacy: .private)")
            return newDeviceID
        }
    }
}

extension LocalStorageDeviceIDProvider: DeviceIDProvider {
    /// Retrieves or generates a persistent device identifier.
    ///
    /// This method attempts to read a stored device ID from secure local storage. If no device ID
    /// exists (first app launch) or storage operations fail, a new UUID is generated. The method
    /// always returns a device ID, but it may be ephemeral if storage operations fail.
    ///
    /// ## Behavior
    /// 1. **Existing ID found**: Returns the stored device ID
    /// 2. **No ID found**: Generates a new UUID and attempts to store it securely
    /// 3. **Storage failure**: Returns an ephemeral UUID (not persisted but cached)
    /// 4. **Pending Reset**: skips the read; generates a fresh ID and attempts to persist it (see resetDeviceID(onReset:))
    ///
    /// - Returns: A device ID string. This is guaranteed to be non-nil but may be ephemeral
    ///   if persistent storage is unavailable.
    ///
    /// - Note: Ephemeral device IDs will change between app launches and should be avoided
    ///   for production scenarios where device tracking is required.
    /// - Note: Device ID stored in secure local storage (Keychain) with `.whenPasscodeSetThisDeviceOnly`
    ///   accessibility **does persist** when the application is uninstalled and then reinstalled.
    ///   This is the case on real devices, but not with simulators where keychain data is cleared.
    func getOrCreateDeviceID() async -> DeviceID {
        let storage = makeStorage(localStorageName)

        // If the current device ID should be reset, don't even try to read the current device ID.
        // Create and store a new device ID.
        // If storage of new device ID is successful, `resetCurrent` will be set to `false`.
        guard !resetCurrent else {
            AppLog.service.notice("\(AppLog.logHeader(self)) ℹ️ Current device ID is invalidated. Generating new ID.")
            return await createAndStoreNewDeviceID(using: storage)
        }

        // Attempt to read existing device ID
        switch await storage.readString(key: Self.DEVICE_ID_KEY, secureLevel: .encrypted) {
        case let .success(deviceID):
            AppLog.service.notice("\(AppLog.logHeader(self)) ✅ Device ID found in LocalStorage: \(deviceID, privacy: .private)")
            return deviceID

        case .failure(.keyNotFound), .failure(.typeMismatch):
            // Expected case: first app launch or corrupted data
            AppLog.service.info("\(AppLog.logHeader(self)) 📱 Device ID not found in LocalStorage. Generating new ID.")
            return await createAndStoreNewDeviceID(using: storage)

        case let .failure(error):
            // Unexpected storage error
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to read device ID from storage: \(error)")
            return await createAndStoreNewDeviceID(using: storage)
        }
    }

    /// Marks the stored device ID as invalidated and registers `onReset`.
    ///
    /// The reset is deferred: the next `getOrCreateDeviceID()` call generates
    /// and persists a fresh ID. `onReset` is invoked at the moment that
    /// persistence succeeds — later in the same session if the device was
    /// locked (e.g. upon unlock) — and it is:
    ///
    /// - **at most once** (the action is consumed upon invocation);
    /// - **possibly never**: the app is terminated before completion, or the
    ///   device cannot persist at all (e.g. no passcode with
    ///   `.whenPasscodeSetThisDeviceOnly` — in that case the persistent flag
    ///   is never set, and each launch re-triggers the reset: this is the
    ///   correct behavior).
    ///
    /// - Note: The `onReset` action is invoked — and awaited — on this actor's
    ///   executor at the moment the replacement ID is persisted, i.e. during a
    ///   later `getOrCreateDeviceID()` call — not when this method is called.
    ///   The action is `async`: it may perform its own I/O (e.g. persisting the
    ///   first-launch flag).
    /// - Note: If called again while a reset is pending, the previous action
    ///   is discarded (last call wins).
    func resetDeviceID(onReset: @escaping ResetDeviceIDCompletionAction) async {
        resetCurrent = true
        resetCurrentPostAction = onReset
        // Reset `cachedDeviceID` to avoid re-using existing one if a read
        // occurs concurrently while a new device ID isn't re-assigned.
        cachedDeviceID = nil
    }
}
