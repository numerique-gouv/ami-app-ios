//
//  NotificationEventPayloadDecodable.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Wire-format decoding for `NotificationEventPayload`: the payload JSON carries
/// the deep link under the `app_url` key.
extension NotificationEventPayload: Decodable {
    /// Throws when `app_url` is missing or not a valid URL.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let applicationUrl = try container.decode(URL.self, forKey: .applicationUrl)
        self.init(applicationUrl: applicationUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case applicationUrl = "app_url"
    }
}
