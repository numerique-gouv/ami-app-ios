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

    static func name() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Unknown name"
    }

    static func version() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown version"
    }

    static func id() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? "Unknown Id"
    }
}
