//
//  AppBundle.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 26/02/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum AppBundle {
    static func path(for embeddedFileNamed: String, ofType: String) -> String? {
        Bundle.main.path(forResource: embeddedFileNamed, ofType: ofType)
    }

    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown name"

    static var version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown version"

    static var build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown build number"

    static var identifier = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "Unknown Id"
}
