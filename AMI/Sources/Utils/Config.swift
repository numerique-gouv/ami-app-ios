//
//  Config.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//
import Foundation

final class Config {
    static let shared = Config()

    #if IS_AMI_STAGING
        var BASE_URL = URL(string: "https://ami-back-staging.osc-fr1.scalingo.io")!
    #elseif IS_AMI_PRODUCTION
        var BASE_URL = URL(string: "https://ami-back-prod.osc-secnum-fr1.scalingo.io")!
    #endif

    private init() {}
}
