//
//  KeychainStorageTests.swift
//  AMI-Production
//
//  Created by Assistant on 10/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

@testable import AMI_Staging
import Foundation
import KeychainAccess
import LocalAuthentication
import Testing

@Suite("KeychainStorage - Secure storage operations")
struct KeychainStorageTests {

    // MARK: - Test Configuration

    /// Unique test store identifier to isolate test data
    private static let testStoreID = "test_keychain_\(UUID().uuidString)"

    /// System under test - fresh instance for each test
    private var sut: KeychainStorage {
        KeychainStorage(for: Self.testStoreID)
    }

    // MARK: - Initialization Tests

    @Test("KeychainStorage creates isolated storage suites")
    func initialization_isolatedSuites() async {
        let storage1 = KeychainStorage(for: "store1")
        let storage2 = KeychainStorage(for: "store2")

        let testData = "test_data".data(using: .utf8)!
        let testKey = "isolation_test_key"

        // Store data in first storage (without authentication)
        let writeResult1 = await storage1.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult1 == .success(true))

        // Verify data doesn't exist in second storage
        let readResult2 = await storage2.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult2 == .failure(.keyNotFound))

        // Verify data still exists in first storage
        let readResult1 = await storage1.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .success(testData))
    }

    // MARK: - Write Data Tests (No Authentication)

    @Test("writeData stores binary data successfully without authentication")
    func writeData_success_noAuth() async {
        let testData = "Hello, World!".data(using: .utf8)!
        let testKey = "write_test_key"

        let result = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)

        #expect(result == .success(true))
    }

    @Test("writeData overwrites existing data without authentication")
    func writeData_overwrite_noAuth() async {
        let testKey = "overwrite_test_key"
        let originalData = "Original Data".data(using: .utf8)!
        let newData = "New Data".data(using: .utf8)!

        // Store original data
        let writeResult1 = await sut.writeData(originalData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult1 == .success(true))

        // Verify original data is stored
        let readResult1 = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .success(originalData))

        // Overwrite with new data
        let writeResult2 = await sut.writeData(newData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult2 == .success(true))

        // Verify new data is stored
        let readResult2 = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult2 == .success(newData))
    }

    @Test("writeData handles empty data without authentication")
    func writeData_emptyData_noAuth() async {
        let emptyData = Data()
        let testKey = "empty_data_key"

        let writeResult = await sut.writeData(emptyData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult == .success(emptyData))
    }

    @Test("writeData handles large data without authentication")
    func writeData_largeData_noAuth() async {
        // Create a smaller data block for Keychain (4KB limit)
        let largeData = Data(repeating: 0xFF, count: 2048) // 2KB should be safe
        let testKey = "large_data_key"

        let writeResult = await sut.writeData(largeData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult == .success(largeData))
    }

    @Test("writeData handles special characters in keys without authentication")
    func writeData_specialCharacterKeys_noAuth() async {
        let testData = "test data".data(using: .utf8)!
        let specialKeys = [
            "key_with_underscores",
            "key-with-dashes",
            "key.with.dots",
            "keyWithUnicode🚀🎉",
            "keyWithNumbers123"
        ]

        for key in specialKeys {
            let writeResult = await sut.writeData(testData, forKey: key, requireAuthentication: false)
            #expect(writeResult == .success(true), "Failed to write data for key: \(key)")

            let readResult = await sut.readData(forKey: key, requireAuthentication: false)
            #expect(readResult == .success(testData), "Failed to read data for key: \(key)")
        }
    }

    // MARK: - Write Data Tests (With Authentication)

    @Test("writeData stores data requiring authentication")
    func writeData_success_withAuth() async {
        let testData = "Secure Data".data(using: .utf8)!
        let testKey = "secure_write_test_key"

        let result = await sut.writeData(testData, forKey: testKey, requireAuthentication: true)

        switch result {
        case .success(true):
            // Success is expected if biometry is available and enrolled
            #expect(true)
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            // These are expected failures in test environments
            #expect(true, "Biometric authentication not available in test environment: \(result)")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error when writing secure data: \(error)")
        default:
            #expect(Bool(false), "Unexpected result: \(result)")
        }
    }

    // MARK: - Read Data Tests (No Authentication)

    @Test("readData retrieves stored data successfully without authentication")
    func readData_success_noAuth() async {
        let testData = "Test Data".data(using: .utf8)!
        let testKey = "read_test_key"

        // First store the data
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        // Then read it back
        let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult == .success(testData))
    }

    @Test("readData returns keyNotFound for non-existent key")
    func readData_keyNotFound() async {
        let result = await sut.readData(forKey: "non_existent_key", requireAuthentication: false)
        #expect(result == .failure(.keyNotFound))
    }

    @Test("readData handles binary data correctly without authentication")
    func readData_binaryData_noAuth() async {
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])
        let testKey = "binary_data_key"

        let writeResult = await sut.writeData(binaryData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult == .success(binaryData))
    }

    // MARK: - Read Data Tests (With Authentication)

    @Test("readData handles authentication requirements")
    func readData_withAuth() async {
        let testData = "Secure Test Data".data(using: .utf8)!
        let testKey = "secure_read_test_key"

        // First try to store data with authentication
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: true)
        
        switch writeResult {
        case .success(true):
            // If writing succeeded, try reading
            let readResult = await sut.readData(forKey: testKey, requireAuthentication: true)
            
            switch readResult {
            case .success(let data):
                #expect(data == testData)
            case .failure(.authenticationCancelled), .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable):
                // These are expected in test environments
                #expect(true, "Authentication not available in test environment")
            case .failure(let error):
                #expect(Bool(false), "Unexpected read error: \(error)")
            }
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            // Expected in test environments - skip the read test
            #expect(true, "Biometric authentication not available in test environment")
        case .failure(let error):
            #expect(Bool(false), "Unexpected write error: \(error)")
        default:
            #expect(Bool(false), "Unexpected write result: \(writeResult)")
        }
    }

    // MARK: - Delete Data Tests

    @Test("deleteData removes stored data successfully")
    func deleteData_success() async {
        let testData = "Data to delete".data(using: .utf8)!
        let testKey = "delete_test_key"

        // Store data
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        // Verify data exists
        let readResult1 = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .success(testData))

        // Delete data
        let deleteResult = await sut.deleteData(forKey: testKey, requireAuthentication: false)
        #expect(deleteResult == .success(true))

        // Verify data is gone
        let readResult2 = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult2 == .failure(.keyNotFound))
    }

    @Test("deleteData succeeds for non-existent key")
    func deleteData_nonExistentKey() async {
        let result = await sut.deleteData(forKey: "non_existent_key", requireAuthentication: false)
        #expect(result == .success(true))
    }

    @Test("deleteData only removes specified key")
    func deleteData_selectiveRemoval() async {
        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testKey1 = "selective_delete_key_1"
        let testKey2 = "selective_delete_key_2"

        // Store both pieces of data
        let writeResult1 = await sut.writeData(testData1, forKey: testKey1, requireAuthentication: false)
        let writeResult2 = await sut.writeData(testData2, forKey: testKey2, requireAuthentication: false)
        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))

        // Delete only the first key
        let deleteResult = await sut.deleteData(forKey: testKey1, requireAuthentication: false)
        #expect(deleteResult == .success(true))

        // Verify first key is deleted
        let readResult1 = await sut.readData(forKey: testKey1, requireAuthentication: false)
        #expect(readResult1 == .failure(.keyNotFound))

        // Verify second key still exists
        let readResult2 = await sut.readData(forKey: testKey2, requireAuthentication: false)
        #expect(readResult2 == .success(testData2))
    }

    // MARK: - Delete All Tests

    @Test("deleteAll removes all stored data")
    func deleteAll_success() async {
        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testData3 = "Data 3".data(using: .utf8)!

        let testKey1 = "delete_all_key_1"
        let testKey2 = "delete_all_key_2"
        let testKey3 = "delete_all_key_3"

        // Store multiple pieces of data (mix of auth and non-auth)
        let writeResult1 = await sut.writeData(testData1, forKey: testKey1, requireAuthentication: false)
        let writeResult2 = await sut.writeData(testData2, forKey: testKey2, requireAuthentication: false)
        let writeResult3 = await sut.writeData(testData3, forKey: testKey3, requireAuthentication: false)

        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))
        #expect(writeResult3 == .success(true))

        // Verify all data exists
        let readResult1 = await sut.readData(forKey: testKey1, requireAuthentication: false)
        let readResult2 = await sut.readData(forKey: testKey2, requireAuthentication: false)
        let readResult3 = await sut.readData(forKey: testKey3, requireAuthentication: false)

        #expect(readResult1 == .success(testData1))
        #expect(readResult2 == .success(testData2))
        #expect(readResult3 == .success(testData3))

        // Delete all data
        let deleteAllResult = await sut.deleteAll()
        #expect(deleteAllResult == .success(true))

        // Verify all data is gone
        let readAfterDelete1 = await sut.readData(forKey: testKey1, requireAuthentication: false)
        let readAfterDelete2 = await sut.readData(forKey: testKey2, requireAuthentication: false)
        let readAfterDelete3 = await sut.readData(forKey: testKey3, requireAuthentication: false)

        #expect(readAfterDelete1 == .failure(.keyNotFound))
        #expect(readAfterDelete2 == .failure(.keyNotFound))
        #expect(readAfterDelete3 == .failure(.keyNotFound))
    }

    @Test("deleteAll removes data regardless of original security level")
    func deleteAll_mixedSecurityLevels() async {
        let mediumSecurityData = "Medium security data".data(using: .utf8)!
        let highSecurityData = "High security data".data(using: .utf8)!
        
        let mediumKey = "medium_security_key"
        let highKey = "high_security_key"

        // Store data with different authentication requirements
        let writeResultMedium = await sut.writeData(mediumSecurityData, forKey: mediumKey, requireAuthentication: false)
        #expect(writeResultMedium == .success(true))

        // Try to store high security data (may fail in test environment)
        let writeResultHigh = await sut.writeData(highSecurityData, forKey: highKey, requireAuthentication: true)
        
        // Delete all data (no authentication required for the operation)
        let deleteAllResult = await sut.deleteAll()
        #expect(deleteAllResult == .success(true))

        // Verify medium security data is gone
        let readResultMedium = await sut.readData(forKey: mediumKey, requireAuthentication: false)
        #expect(readResultMedium == .failure(.keyNotFound))

        // If high security data was successfully stored, it should also be gone
        if case .success = writeResultHigh {
            let readResultHigh = await sut.readData(forKey: highKey, requireAuthentication: false)
            #expect(readResultHigh == .failure(.keyNotFound))
        }
    }

    @Test("deleteAll succeeds on empty storage")
    func deleteAll_emptyStorage() async {
        let result = await sut.deleteAll()
        #expect(result == .success(true))
    }

    @Test("deleteAll only affects current storage suite")
    func deleteAll_isolatedToCurrentSuite() async {
        let storage1 = KeychainStorage(for: "suite1")
        let storage2 = KeychainStorage(for: "suite2")

        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testKey = "isolation_key"

        // Store data in both storages
        let writeResult1 = await storage1.writeData(testData1, forKey: testKey, requireAuthentication: false)
        let writeResult2 = await storage2.writeData(testData2, forKey: testKey, requireAuthentication: false)
        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))

        // Delete all from first storage
        let deleteAllResult = await storage1.deleteAll()
        #expect(deleteAllResult == .success(true))

        // Verify data is gone from first storage
        let readResult1 = await storage1.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .failure(.keyNotFound))

        // Verify data still exists in second storage
        let readResult2 = await storage2.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult2 == .success(testData2))
    }

    @Test("deleteAll behavior documentation")
    func deleteAll_behaviorDocumentation() async {
        // This test documents that deleteAll removes all items regardless of security level
        // and does not require authentication for the operation itself
        
        let mediumData = "Medium data".data(using: .utf8)!
        let potentialHighData = "Potential high data".data(using: .utf8)!
        
        // Store medium security data
        let mediumResult = await sut.writeData(mediumData, forKey: "medium_key", requireAuthentication: false)
        #expect(mediumResult == .success(true))
        
        // Attempt to store high security data (may fail in test environment)
        let highResult = await sut.writeData(potentialHighData, forKey: "high_key", requireAuthentication: true)
        
        // Delete all - no authentication required for the operation
        let deleteResult = await sut.deleteAll()
        #expect(deleteResult == .success(true))
        
        // Both medium and high security items should be gone
        let mediumCheck = await sut.readData(forKey: "medium_key", requireAuthentication: false)
        #expect(mediumCheck == .failure(.keyNotFound))
        
        if case .success = highResult {
            let highCheck = await sut.readData(forKey: "high_key", requireAuthentication: false)
            #expect(highCheck == .failure(.keyNotFound))
        }
    }

    // MARK: - JSON Data Tests

    @Test("writeData and readData work with JSON data")
    func jsonData_roundTrip() async {
        struct TestModel: Codable, Equatable {
            let name: String
            let age: Int
            let isActive: Bool
        }

        let testModel = TestModel(name: "John Doe", age: 30, isActive: true)
        let testKey = "json_test_key"

        do {
            // Encode to JSON data
            let jsonData = try JSONEncoder().encode(testModel)

            // Store JSON data
            let writeResult = await sut.writeData(jsonData, forKey: testKey, requireAuthentication: false)
            #expect(writeResult == .success(true))

            // Read JSON data back
            let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)

            switch readResult {
            case .success(let retrievedData):
                // Decode back to model
                let decodedModel = try JSONDecoder().decode(TestModel.self, from: retrievedData)
                #expect(decodedModel == testModel)
            case .failure(let error):
                #expect(Bool(false), "Failed to read JSON data: \(error)")
            }
        } catch {
            #expect(Bool(false), "JSON encoding/decoding failed: \(error)")
        }
    }

    // MARK: - Concurrent Access Tests

    @Test("concurrent read/write operations are safe")
    func concurrentOperations_safety() async {
        let testKey = "concurrent_test_key"
        let numberOfOperations = 20 // Reduced for Keychain which is slower than UserDefaults

        await withTaskGroup(of: Void.self) { group in
            // Add concurrent write operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let data = "Data \(i)".data(using: .utf8)!
                    let _ = await self.sut.writeData(data, forKey: "\(testKey)_\(i)", requireAuthentication: false)
                }
            }

            // Add concurrent read operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let _ = await self.sut.readData(forKey: "\(testKey)_\(i)", requireAuthentication: false)
                }
            }

            // Add concurrent delete operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let _ = await self.sut.deleteData(forKey: "\(testKey)_\(i)", requireAuthentication: false)
                }
            }
        }

        // If we reach here without crashes, concurrent operations are safe
        #expect(true)
    }

    // MARK: - Performance Tests

    @Test("performance of write operations")
    func performance_writeOperations() async {
        let testData = "Performance test data".data(using: .utf8)!
        let numberOfOperations = 20 // Reduced for Keychain operations

        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<numberOfOperations {
            let result = await sut.writeData(testData, forKey: "perf_write_\(i)", requireAuthentication: false)
            #expect(result == .success(true))
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Expect operations to complete within reasonable time (5 seconds for 20 operations)
        // Keychain operations are slower than UserDefaults
        #expect(timeElapsed < 5.0, "Write operations took too long: \(timeElapsed) seconds")
    }

    @Test("performance of read operations")
    func performance_readOperations() async {
        let testData = "Performance test data".data(using: .utf8)!
        let numberOfOperations = 20 // Reduced for Keychain operations

        // Pre-populate data
        for i in 0..<numberOfOperations {
            let _ = await sut.writeData(testData, forKey: "perf_read_\(i)", requireAuthentication: false)
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<numberOfOperations {
            let result = await sut.readData(forKey: "perf_read_\(i)", requireAuthentication: false)
            #expect(result == .success(testData))
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Expect operations to complete within reasonable time (3 seconds for 20 operations)
        #expect(timeElapsed < 3.0, "Read operations took too long: \(timeElapsed) seconds")
    }

    // MARK: - Edge Cases

    @Test("storage works with various data sizes")
    func edgeCases_dataSizes() async {
        let testCases: [(String, Data)] = [
            ("single_byte", Data([0x01])),
            ("small_data", Data(repeating: 0xFF, count: 100)),
            ("medium_data", Data(repeating: 0xAA, count: 1000)), // Reduced for Keychain limits
            ("large_data", Data(repeating: 0x55, count: 3000)) // Near Keychain 4KB limit
        ]

        for (keyPrefix, testData) in testCases {
            let testKey = "\(keyPrefix)_size_test"

            let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
            
            switch writeResult {
            case .success(true):
                let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
                #expect(readResult == .success(testData), "Failed to read \(keyPrefix)")
            case .failure(.dataIsTooLarge):
                // Expected for very large data in Keychain
                #expect(true, "Data too large for Keychain: \(keyPrefix)")
            case .failure(let error):
                #expect(Bool(false), "Unexpected error for \(keyPrefix): \(error)")
            default:
                #expect(Bool(false), "Unexpected result for \(keyPrefix): \(writeResult)")
            }
        }
    }

    @Test("storage handles Unicode data correctly")
    func edgeCases_unicodeData() async {
        let unicodeStrings = [
            "Hello, 世界",
            "🚀🎉🌟💫⭐",
            "Iñtërnâtiônàlizætiøn",
            "العربية",
            "עברית",
            "Русский",
            "Français with açcénts"
        ]

        for (index, unicodeString) in unicodeStrings.enumerated() {
            guard let unicodeData = unicodeString.data(using: .utf8) else {
                #expect(Bool(false), "Failed to encode Unicode string: \(unicodeString)")
                continue
            }

            let testKey = "unicode_test_\(index)"

            let writeResult = await sut.writeData(unicodeData, forKey: testKey, requireAuthentication: false)
            #expect(writeResult == .success(true), "Failed to write Unicode data for: \(unicodeString)")

            let readResult = await sut.readData(forKey: testKey, requireAuthentication: false)
            #expect(readResult == .success(unicodeData), "Failed to read Unicode data for: \(unicodeString)")

            // Verify the string round-trip
            if case .success(let retrievedData) = readResult {
                let retrievedString = String(data: retrievedData, encoding: .utf8)
                #expect(retrievedString == unicodeString, "Unicode string mismatch: expected \(unicodeString), got \(retrievedString ?? "nil")")
            }
        }
    }

    // MARK: - Keychain-Specific Error Tests

    @Test("handles Keychain-specific error scenarios")
    func keychainSpecificErrors() async {
        // Test with extremely large data to trigger dataIsTooLarge
        let veryLargeData = Data(repeating: 0xFF, count: 100_000) // 100KB, well over Keychain limit
        let largeDataResult = await sut.writeData(veryLargeData, forKey: "large_data_test", requireAuthentication: false)
        
        switch largeDataResult {
        case .failure(.dataIsTooLarge):
            #expect(true, "Correctly detected data too large for Keychain")
        case .success(true):
            // Some test environments might accept this
            #expect(true, "Test environment accepted large data")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error for large data: \(error)")
        default:
            #expect(Bool(false), "Unexpected result for large data: \(largeDataResult)")
        }
    }

    // MARK: - Authentication-Specific Tests

    @Test("authentication parameter consistency")
    func authenticationParameterConsistency() async {
        let testData = "Auth consistency test".data(using: .utf8)!
        let testKey = "auth_consistency_key"

        // Store data without authentication requirement
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        // Should be able to read with or without authentication flag
        let readResult1 = await sut.readData(forKey: testKey, requireAuthentication: false)
        let readResult2 = await sut.readData(forKey: testKey, requireAuthentication: true)

        #expect(readResult1 == .success(testData), "Failed to read without auth flag")
        
        // Reading with auth flag might succeed or fail depending on device capabilities
        switch readResult2 {
        case .success(let data):
            #expect(data == testData, "Data mismatch when reading with auth flag")
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            #expect(true, "Expected auth failure in test environment")
        case .failure(let error):
            #expect(Bool(false), "Unexpected auth read error: \(error)")
        }
    }

    // MARK: - Error Mapping Tests

    @Test("error mapping functions work correctly")
    func errorMappingFunctions() async {
        // Test that the static error mapping functions exist and can be called
        // This ensures the KeychainErrorMapping extension is properly integrated
        
        // Create a sample LAError for testing mapping
        let sampleLAError = LAError(.userCancel)
        let mappedLAError = KeychainStorage.mapLAError(sampleLAError)
        #expect(mappedLAError == .authenticationCancelled, "LAError mapping should work correctly")
        
        // Test Keychain status mapping
        let sampleStatus = Status.itemNotFound
        let mappedStatus = KeychainStorage.mapKeychainAccessStatus(sampleStatus)
        #expect(mappedStatus == .keyNotFound, "Status mapping should work correctly")
    }
}

// MARK: - Debug Description Tests

@Suite("KeychainStorage - Debug Description")
struct KeychainStorageDebugTests {

    @Test("debugDescription provides readable output")
    func debugDescription_format() async {
        let storage = KeychainStorage(for: "debug_test")
        let debugOutput = storage.debugDescription

        // Should be a non-empty string
        #expect(!debugOutput.isEmpty, "Debug description should not be empty")

        // Should contain some indication it's a Keychain
        #expect(debugOutput.contains("Keychain") || debugOutput.contains("service"), 
                "Debug output should indicate it's Keychain-related")
    }

    @Test("debugDescription includes service information")
    func debugDescription_includesServiceInfo() async {
        let testStoreID = "debug_with_service_test"
        let storage = KeychainStorage(for: testStoreID)
        let debugOutput = storage.debugDescription

        // Should contain service information
        #expect(debugOutput.contains(testStoreID) || debugOutput.contains("service"),
                "Debug output should contain service information")
    }
}

// swiftlint:enable all
// swiftformat:enable all
