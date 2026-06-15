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

        let deviceId = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
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
}
