//
//  Config.swift
//  AMI
//
//  Created by Aline Bonnet on 19/10/2025.
//
import Foundation

class Config {
    static let shared: Config = Config()
    
    private init() {
        BASE_URL = Self.getValue(for: "BASE_URL")
    }
    
    var BASE_URL: String
    
    var CURRENT_ENV: String {
        return Self.getValue(for: "CURRENT_ENV", defaultValue: "DEFAUT_VALUE_FOR_CURRENT_ENV")
    }
    
    static func getValue(for key : String, defaultValue: String = "") -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? defaultValue
    }
}

