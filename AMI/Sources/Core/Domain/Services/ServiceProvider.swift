//
//  ServiceProvider.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 07/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

enum ServiceProvider: Hashable, Sendable {
    case servicePublic
    case demarchesNumeriques
}

extension ServiceProvider: CustomStringConvertible {
    var description: String {
        switch self {
        case .servicePublic: "servicePublic"
        case .demarchesNumeriques: "demarchesNumeriques"
        }
    }
}
