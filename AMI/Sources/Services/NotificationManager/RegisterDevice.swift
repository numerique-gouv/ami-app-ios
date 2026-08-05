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
    let apnsToken: String
    let deviceId: String
    let platform: String = "ios"
    let deviceModel: String
    let appVersion: String

    private enum CodingKeys: String, CodingKey {
        case apnsToken = "fcm_token"
        case deviceId = "device_id"
        case platform
        case deviceModel = "model"
        case appVersion = "app_version"
    }
}

final actor RegisterDevice {
    func registerDevice(baseUrl: URL, apnsToken: String, userAuthenticationToken: String) async {
        let deviceId = await DeviceID.getOrCreateDeviceID()
        let deviceModel = await UIDevice.current.model
        let appVersion = AppBundle.version

        AppLog.service.notice(
            """
            \(AppLog.logHeader(self)) ✅ Registering device
            \tfcmToken=\(apnsToken, privacy: .private)
            \tdeviceId=\(deviceId, privacy: .private)
            \tmodel=\(deviceModel)
            \tplatform=ios app_version=\(appVersion)
            """
        )

        // prepare registration data.
        let registerInput = RegisterDeviceRequestInput(apnsToken: apnsToken,
                                                       deviceId: deviceId,
                                                       deviceModel: deviceModel,
                                                       appVersion: appVersion)

        // Make the API request
        await registerDevice(baseUrl: baseUrl,
                             userAuthenticationToken: userAuthenticationToken,
                             input: registerInput)
    }

    private func registerDevice(baseUrl: URL, userAuthenticationToken: String, input: RegisterDeviceRequestInput) async {
        let url = baseUrl.appendingPathComponent("/api/v1/users/registrations")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(userAuthenticationToken, forHTTPHeaderField: "Authorization")

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
