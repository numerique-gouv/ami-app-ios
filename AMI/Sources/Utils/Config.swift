//
//  Config.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//
import Foundation

final class Config {
    static let shared = Config()

    let BASE_URL = URL(string: Secrets.baseUrlString)!
    let OIDC_HOSTS = Secrets.oidcHosts

    private init() {}
}
