//
//  NotificationEventDecodable.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

extension NotificationEventPayload: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let applicationUrl = try container.decode(URL.self, forKey: .applicationUrl)
        self.init(applicationUrl: applicationUrl)
    }

    private enum CodingKeys: String, CodingKey {
        case applicationUrl = "app_url"
    }
}
