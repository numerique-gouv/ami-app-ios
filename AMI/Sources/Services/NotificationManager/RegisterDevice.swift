//
//  RegisterDevice.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 07/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import WebKit

private struct RegisterDeviceRequestInput: Encodable {
    let token: String
    let deviceId: String
    let platform: String = "ios"
    let deviceModel: String
    let appVersion: String

    private enum CodingKeys: String, CodingKey {
        case token = "fcm_token"
        case deviceId = "device_id"
        case platform
        case deviceModel = "model"
        case appVersion = "app_version"
    }
}

class RegisterDevice {
    // The name of the cookie containing the authentication token.
    private static let AUTHENTICATION_COOKIE_NAME = "token"

    // The name of the LocalStorage to store device id.
    private static let DEVICE_ID_LOCAL_STORAGE_NAME = "applicationData"
    // The key used to store `device id`.` in the LocalStorage.
    private static let DEVICE_ID_KEY = "deviceID"

    // Get the auth token from cookie store.
    // Return nil if no token is found.
    private func getAuthToken(webviewConfiguration: WKWebViewConfiguration) async -> String? {
        await webviewConfiguration
            .websiteDataStore
            .httpCookieStore
            .allCookies()
            .first(where: { $0.name == Self.AUTHENTICATION_COOKIE_NAME })?.value.replacingOccurrences(of: "\"", with: "")
    }

    func registerDevice(baseUrl: URL, token: String, webviewConfiguration: WKWebViewConfiguration) async {
        guard let authToken = await getAuthToken(webviewConfiguration: webviewConfiguration) else {
            AppLog.service.warning("\(AppLog.logHeader(self)) ⚠️ No 'token' cookie found - cannot register device")
            return
        }

        let deviceId = await getOrCreateDeviceID()
        let deviceModel = await UIDevice.current.model
        let appVersion = AppBundle.version()

        AppLog.service.notice(
            """
            \(AppLog.logHeader(self)) ✅ Registering device
            \tfcmToken=\(token, privacy: .private)
            \tdeviceId=\(deviceId, privacy: .private)
            \tmodel=\(deviceModel)
            \tplatform=ios app_version=\(appVersion)
            """
        )

        // prepare registration data.
        let registerInput = RegisterDeviceRequestInput(token: token,
                                                       deviceId: deviceId,
                                                       deviceModel: deviceModel,
                                                       appVersion: appVersion)

        // Make the API request
        await registerDevice(baseUrl: baseUrl,
                             authenticationToken: authToken,
                             input: registerInput)
    }

    private func registerDevice(baseUrl: URL, authenticationToken: String, input: RegisterDeviceRequestInput) async {
        let url = baseUrl.appendingPathComponent("/api/v1/users/registrations")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authenticationToken, forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(["subscription": input])

            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    AppLog.service.notice("\(AppLog.logHeader(self)) ✅ Device registered successfully")
                } else {
                    AppLog.service.warning("\(AppLog.logHeader(self)) ⚠️ Device registration failed with status \(httpResponse.statusCode)")
                }
            }
        } catch {
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Device registration error: \(error.localizedDescription)")
        }
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
    private func getOrCreateDeviceID() async -> String {
        let storage = LocalStorageRepository(for: Self.DEVICE_ID_LOCAL_STORAGE_NAME)

        // Attempt to read existing device ID
        switch await storage.readString(key: Self.DEVICE_ID_KEY, secureLevel: .medium) {
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

    /// Creates a new device ID and attempts to store it persistently.
    ///
    /// - Parameter storage: The storage repository to use for persistence
    /// - Returns: A new device ID (either persisted or ephemeral)
    private func createAndStoreNewDeviceID(using storage: LocalStorageRepository) async -> String {
        let newDeviceID = UUID().uuidString

        switch await storage.writeString(key: Self.DEVICE_ID_KEY, value: newDeviceID, secureLevel: .medium) {
        case .success:
            AppLog.service.notice("\(AppLog.logHeader(self)) ✅ Device ID successfully stored: \(newDeviceID, privacy: .private)")
            return newDeviceID

        case let .failure(error):
            AppLog.service.error("\(AppLog.logHeader(self)) ❌ Failed to persist device ID: \(error)")
            AppLog.service.warning("\(AppLog.logHeader(self)) ⚠️ Using ephemeral device ID: \(newDeviceID, privacy: .private)")
            return newDeviceID
        }
    }
}
