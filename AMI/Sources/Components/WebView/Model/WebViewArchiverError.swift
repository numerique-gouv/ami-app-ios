//
//  WebViewArchiverError.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 22/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum WebViewArchiverError: Error {
    case unsupportedScheme(String?)
    case unableToArchive(Error)
    case unableToRestore(Error)
}
