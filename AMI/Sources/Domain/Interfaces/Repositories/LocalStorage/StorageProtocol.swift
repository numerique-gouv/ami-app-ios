//
//  StorageProtocol.swift
//  AMI-xcodegen
//
//  Created by Nicolas Buquet on 03/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the interface for basic storage operations without security levels.
/// Implementations typically use simple persistence mechanisms like UserDefaults
/// for storing non-sensitive data.
protocol StorageProtocol {
    /// Stores binary data for the given key.
    /// - Parameters:
    ///   - data: The binary data to store.
    ///   - key: The unique identifier for the stored data.
    func writeData(_ data: Data, forKey key: String) async -> Result<Bool, LocalStorageErrorType>

    /// Retrieves stored binary data for the given key.
    /// - Parameter key: The unique identifier for the stored data.
    /// - Returns: The stored binary data, or `nil` if no data exists for the key.
    func readData(forKey key: String) async -> Result<Data, LocalStorageErrorType>

    /// Removes stored data for the given key.
    /// - Parameter key: The unique identifier for the data to remove.
    func deleteData(forKey key: String) async -> Result<Bool, LocalStorageErrorType>
}
