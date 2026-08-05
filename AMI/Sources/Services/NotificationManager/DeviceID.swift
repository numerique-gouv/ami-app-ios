//
//  DeviceID.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/08/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

final actor DeviceID {
    // The aliased type of Device ID value
    typealias DeviceIdType = String

    // The name of the LocalStorage to store device id.
    private static let DEVICE_ID_LOCAL_STORAGE_NAME = "applicationData"
    // The key used to store `device id`.` in the LocalStorage.
    private static let DEVICE_ID_KEY = "deviceID"

    /// Retrieves or generates a persistent device identifier.
    ///
    /// This method attempts to read a stored device ID from secure local storage. If no device ID
    /// exists (first app launch) or storage operations fail, a new UUID is generated. The method
    /// always returns a device ID, but it may be ephemeral if storage operations fail.
    ///
    /// ## Behavior
    /// 1. **Existing ID found**: Returns the stored device ID
    /// 2. **No ID found**: Generates a new UUID and attempts to store it securely
    /// 3. **Storage failure**: Returns an ephemeral UUID (not persisted)
    ///
    /// - Returns: A device ID string. This is guaranteed to be non-nil but may be ephemeral
    ///   if persistent storage is unavailable.
    ///
    /// - Note: Ephemeral device IDs will change between app launches and should be avoided
    ///   for production scenarios where device tracking is required.
    /// - Note: Device ID stored in secure local storage (Keychain) with `.whenPasscodeSetThisDeviceOnly`
    ///   accessibility **does persist** when the application is uninstalled and then reinstalled.
    ///   This is the case on real devices, but not with simulators where keychain data is cleared.
    static func getOrCreateDeviceID() async -> DeviceIdType {
        let storage = LocalStorageRepository(for: Self.DEVICE_ID_LOCAL_STORAGE_NAME)

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

    // The ephemeral Device ID property (used only if deviceID can't be stored in storage repository).
    // This is to avoid generating a new device ID on each call when storage repository is not usable.
    private static var ephemeralDeviceID: DeviceIdType?

    /// Creates a new device ID and attempts to store it persistently.
    ///
    /// - Parameter storage: The storage repository to use for persistence
    /// - Returns: A new device ID (either persisted or ephemeral)
    ///
    /// - Note: If, for any reasion, the newly generated device ID can't be stored in storage repository, the device iD is ephemeral.
    ///   If no ephemeral device ID already exists, store the newly generated device ID as the actual ephemeral ID;
    ///   Then, returns the actual ephemeral ID.
    private static func createAndStoreNewDeviceID(using storage: LocalStorageRepository) async -> DeviceIdType {
        var newDeviceID: DeviceIdType = UUID().uuidString

        switch await storage.writeString(key: Self.DEVICE_ID_KEY, value: newDeviceID, secureLevel: .encrypted) {
        case .success:
            AppLog.service.notice("\(AppLog.logHeader(self)) ✅ Device ID successfully stored: \(newDeviceID, privacy: .private)")
            return newDeviceID

        case let .failure(error):
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to persist device ID: \(error)")

            // If ephemeral device ID already exists, use it rather than the newly generated one (to avoid overriding any already existing ephemeral ID).
            // Else, store newly generated device ID in `ephemeralDeviceID` property (to reuse it next time).
            if let ephemeralDeviceID {
                newDeviceID = ephemeralDeviceID
            } else {
                ephemeralDeviceID = newDeviceID
            }

            AppLog.service.warning("\(AppLog.logHeader(self)) ⚠️ Using ephemeral device ID: \(newDeviceID, privacy: .private)")
            return newDeviceID
        }
    }
}
