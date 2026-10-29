//
//  DeviceID.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/08/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

final actor DeviceID {
    /// The aliased type of Device ID value
    typealias DeviceIdType = String
    /// The reset device ID completion action type
    typealias ResetDeviceIDCompletionAction = @Sendable () -> Void
    /// The factory method to create the LocalStorageRepository
    typealias StorageFactory = @Sendable (String) -> any LocalStorageRepositoryProtocol

    /// DeviceID is global to the application. Make a shared instance available.
    static let shared = DeviceID(localStorageName: DEVICE_ID_LOCAL_STORAGE_NAME, makeStorage: { LocalStorageRepository(for: $0) })

    // The name of the LocalStorage to store device id.
    private static let DEVICE_ID_LOCAL_STORAGE_NAME = "applicationData"
    // The key used to store `device id` in the LocalStorage.
    private static let DEVICE_ID_KEY = "deviceID"

    /// A flag indicating a device ID reset is pending.
    /// Its role is to avoid reusing an invalidated device ID.
    /// While the invalidated device ID can't be reset, an cached device ID will be served.
    private var resetCurrent = false

    /// Action called once the device ID is really reset.
    private var resetCurrentPostAction: ResetDeviceIDCompletionAction?

    /// The cached Device ID property (used only if deviceID can't be stored in storage repository
    /// or when the current device ID is invalidated).
    /// This is to avoid generating a new device ID on each call when storage repository is not usable.
    private var cachedDeviceID: DeviceIdType?

    /// Dependency injection properties to know how to access local storage used to store device ID.
    private let localStorageName: String
    private let makeStorage: StorageFactory

    /// - Parameters:
    ///   - localStorageName: Name of the LocalStorage used to persist the device ID.
    ///   - makeStorage: Factory for the storage repository. Injectable for testing.
    init(localStorageName: String, makeStorage: @escaping StorageFactory) {
        self.localStorageName = localStorageName
        self.makeStorage = makeStorage
    }

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
    ///
    /// - Returns: A device ID string. This is guaranteed to be non-nil but may be ephemeral
    ///   if persistent storage is unavailable.
    ///
    /// - Note: Ephemeral device IDs will change between app launches and should be avoided
    ///   for production scenarios where device tracking is required.
    /// - Note: Device ID stored in secure local storage (Keychain) with `.whenPasscodeSetThisDeviceOnly`
    ///   accessibility **does persist** when the application is uninstalled and then reinstalled.
    ///   This is the case on real devices, but not with simulators where keychain data is cleared.
    func getOrCreateDeviceID() async -> DeviceIdType {
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
    /// - Note: Invoked on this actor's executor. If you need to touch
    ///   `@MainActor` state inside it, type the parameter `@MainActor @Sendable`
    ///   and call `await action()`.
    /// - Note: If called again while a reset is pending, the previous action
    ///   is discarded (last call wins).
    func resetDeviceID(onReset: @escaping ResetDeviceIDCompletionAction) {
        resetCurrent = true
        resetCurrentPostAction = onReset
        // Reset `cachedDeviceID` to avoid re-using existant one if a read
        // occurs concurrently while a new device ID isn't re-assigned.
        cachedDeviceID = nil
    }

    /// Creates a new device ID and attempts to store it persistently.
    ///
    /// - Parameter storage: The storage repository to use for persistence
    /// - Returns: A new device ID (either persisted or ephemeral but cached)
    ///
    /// - Note: If, for any reason, the newly generated device ID can't be stored in storage repository, the device ID is ephemeral.
    ///   If no ephemeral cached device ID already exists, store the newly generated device ID as the actual cached ID;
    ///   Then, returns the actual cached ID.
    private func createAndStoreNewDeviceID(using storage: any LocalStorageRepositoryProtocol) async -> DeviceIdType {
        // Use existing cached device ID if it is already created.
        // This reinforce the cached device ID stability: don't create any new device ID if cached one exists.
        let newDeviceID: DeviceIdType = cachedDeviceID ?? UUID().uuidString

        // Set ephemaral ID to newDeviceID in case a concurrent `createAndStoreNewDeviceID` is called.
        // Although `DeviceID` is an actor, there is a suspension point durong next `await storage.writeString()`
        // that allows concurrent execution of another `createAndStoreNewDeviceID` call.
        cachedDeviceID = newDeviceID

        switch await storage.writeString(key: Self.DEVICE_ID_KEY, value: newDeviceID, secureLevel: .encrypted) {
        case .success:
            AppLog.service.notice("\(AppLog.logHeader(self)) ✅ New device ID successfully stored: \(newDeviceID, privacy: .private)")
            // Always set `resetCurrent` to false when a newly created device ID is successfully stored.
            if resetCurrent {
                // Called optional `resetCurrentPostAction` only if `resetCurrent` is `true`.
                resetCurrentPostAction?()
            }
            resetCurrent = false
            resetCurrentPostAction = nil
            return newDeviceID

        case let .failure(error):
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to persist new device ID: \(error).\nUsing cached device ID: \(newDeviceID, privacy: .private)")
            return newDeviceID
        }
    }
}
