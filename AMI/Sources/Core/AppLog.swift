//
//  AppLog.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 14/04/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation
import os

// Note: os.Logger cannot be called indirectly because its message argument
//       must be fully known at compile time.
//       So, we just instantiate multiple versions to be called directly in the application.

enum AppLog {
    static let app = Logger(subsystem: AppBundle.identifier, category: "application")
    static let view = Logger(subsystem: AppBundle.identifier, category: "view")
    static let viewModel = Logger(subsystem: AppBundle.identifier, category: "viewModel")
    static let service = Logger(subsystem: AppBundle.identifier, category: "service")

    static func logHeader(_ caller: Any? = nil, function: String = #function) -> String {
        switch caller {
        case let .some(caller): "[\(type(of: caller)) - \(function)]"
        case .none: "[<no-caller> - \(function)]"
        }
    }

    // See differences between different log levels here: https://developer.apple.com/documentation/os/generating-log-messages-from-your-code#Choose-the-Appropriate-Log-Level-for-Each-Message

    // Available methods:
    //
    // Captures information about faults and bugs in your code. If an activity object exists, the system captures information for the related process chain.
    // Fault messages are collected to disk up to a storage limit.
    //
    // - error(_ message: OSLogMessage)
    //
    // Captures errors seen during the execution of your code. If an activity object exists, the system captures information for the related process chain.
    // Error messages are collected to disk up to a storage limit.
    //
    // - warning(_ message: OSLogMessage)
    //
    // Captures information that is essential for troubleshooting problems. For example, capture information that might result in a failure.
    // Notice messages are collected to disk up to a storage limit.
    //
    // - notice(_ message: OSLogMessage)
    //
    // Captures information that is helpful, but not essential, to troubleshoot problems.
    // Info messages are not persisted to disk except when collected with the log tool.
    //
    // - info(_ message: OSLogMessage)
    //
    // Captures verbose information during development that is useful only for debugging your code.
    // Debug messages are not persisted to disk.
    //
    // - debug(_ message: OSLogMessage)
}
