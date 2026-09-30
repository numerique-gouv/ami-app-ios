//
//  PSLFinalPayloadRepositoryDefault.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 30/09/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

actor PSLFinalPayloadRepositoryDefault: PSLFinalPayloadRepository {
    private var storage: [String: PSLFinalPayloadType] = [:]

    func save(_ payload: PSLFinalPayloadType) async throws(PSLFinalPayloadRepositoryError) {
        storage[payload.id] = payload
    }
}
