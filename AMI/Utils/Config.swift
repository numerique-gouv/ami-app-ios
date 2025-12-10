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
        BASE_URL = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String ?? ""
    }
    
    var BASE_URL: String
    var CURRENT_ENV: String { return self.getValue(for: "CURRENT_ENV")}
    
    private func getValue(for key : String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return "DEFAUT_VALUE_FOR_\(key)"
        }
        return value
    }
}

