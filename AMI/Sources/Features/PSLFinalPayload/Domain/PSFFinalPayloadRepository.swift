//
//  PSFFinalPayloadRepository.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

protocol PSLFinalPayloadRepository: Sendable {
    func save(_ payload: PSLFinalPayloadType) async throws(PSLFinalPayloadRepositoryError)
}

enum PSLFinalPayloadRepositoryError: Error, Equatable, Sendable {
    case unableToSave(Error)
}
