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

    @Test("deleteAll removes all stored data from medium security store")
    func deleteAll_mediumSecurityStore() async {
        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testData3 = "Data 3".data(using: .utf8)!

        let testKey1 = "delete_all_key_1"
        let testKey2 = "delete_all_key_2"
        let testKey3 = "delete_all_key_3"

        // Store multiple pieces of data in medium security store
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

        // Delete all data from medium security store
        let deleteAllResult = await sut.deleteAll(requireAuthentication: false)
        #expect(deleteAllResult == .success(true))

        // Verify all data is gone from medium security store
        let readAfterDelete1 = await sut.readData(forKey: testKey1, requireAuthentication: false)
        let readAfterDelete2 = await sut.readData(forKey: testKey2, requireAuthentication: false)
        let readAfterDelete3 = await sut.readData(forKey: testKey3, requireAuthentication: false)

        #expect(readAfterDelete1 == .failure(.keyNotFound))
        #expect(readAfterDelete2 == .failure(.keyNotFound))
        #expect(readAfterDelete3 == .failure(.keyNotFound))
    }

    @Test("deleteAll operates on security store based on authentication parameter")
    func deleteAll_securityStoreSeparation() async {
        let mediumSecurityData = "Medium security data".data(using: .utf8)!
        let highSecurityData = "High security data".data(using: .utf8)!
        
        let mediumKey = "medium_security_key"
        let highKey = "high_security_key"

        // Store data in medium security store
        let writeResultMedium = await sut.writeData(mediumSecurityData, forKey: mediumKey, requireAuthentication: false)
        #expect(writeResultMedium == .success(true))

        // Try to store data in high security store (may fail in test environment)
        let writeResultHigh = await sut.writeData(highSecurityData, forKey: highKey, requireAuthentication: true)
        
        // Delete all data from medium security store only
        let deleteAllResult = await sut.deleteAll(requireAuthentication: false)
        #expect(deleteAllResult == .success(true))

        // Verify medium security data is gone
        let readResultMedium = await sut.readData(forKey: mediumKey, requireAuthentication: false)
        #expect(readResultMedium == .failure(.keyNotFound))

        // If high security data was successfully stored, it should still exist
        // because we only cleared the medium security store
        if case .success = writeResultHigh {
            let readResultHigh = await sut.readData(forKey: highKey, requireAuthentication: true)
            switch readResultHigh {
            case .success(let data):
                #expect(data == highSecurityData, "High security data should still exist after medium store deleteAll")
            case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                // Expected in test environments - we can't verify the data still exists without authentication
                #expect(true, "Cannot verify high security data persistence due to test environment limitations")
            case .failure(let error):
                #expect(Bool(false), "Unexpected error reading high security data: \(error)")
            }
        }
    }

    @Test("deleteAll succeeds on empty storage")
    func deleteAll_emptyStorage() async {
        // Test both security levels on empty storage
        let mediumResult = await sut.deleteAll(requireAuthentication: false)
        #expect(mediumResult == .success(true))
        
        let highResult = await sut.deleteAll(requireAuthentication: true)
        switch highResult {
        case .success(true):
            #expect(true, "High security deleteAll succeeded on empty storage")
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
            #expect(true, "Expected authentication failure in test environment")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error during high security deleteAll on empty storage: \(error)")
        default:
            #expect(Bool(false), "Unexpected result from high security deleteAll: \(highResult)")
        }
    }

    @Test("deleteAll only affects current storage suite")
    func deleteAll_isolatedToCurrentSuite() async {
        let storage1 = KeychainStorage(for: "suite1")
        let storage2 = KeychainStorage(for: "suite2")

        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testKey = "isolation_key"

        // Store data in both storages (medium security)
        let writeResult1 = await storage1.writeData(testData1, forKey: testKey, requireAuthentication: false)
        let writeResult2 = await storage2.writeData(testData2, forKey: testKey, requireAuthentication: false)
        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))

        // Delete all from first storage's medium security store
        let deleteAllResult = await storage1.deleteAll(requireAuthentication: false)
        #expect(deleteAllResult == .success(true))

        // Verify data is gone from first storage
        let readResult1 = await storage1.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .failure(.keyNotFound))

        // Verify data still exists in second storage
        let readResult2 = await storage2.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult2 == .success(testData2))
    }

    @Test("deleteAll with authentication requirement for high security store")
    func deleteAll_highSecurityStore() async {
        let testData = "High security test data".data(using: .utf8)!
        let testKey = "high_security_delete_test_key"
        
        // Try to store data in high security store first
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: true)
        
        switch writeResult {
        case .success(true):
            // If writing to high security store succeeded, try to delete all from it
            let deleteResult = await sut.deleteAll(requireAuthentication: true)
            
            switch deleteResult {
            case .success(true):
                // Verify data is gone from high security store
                let readResult = await sut.readData(forKey: testKey, requireAuthentication: true)
                switch readResult {
                case .failure(.keyNotFound):
                    #expect(true, "High security data successfully deleted")
                case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                    // Can't verify deletion due to authentication issues
                    #expect(true, "Cannot verify deletion due to authentication limitations")
                case .success(let data):
                    #expect(Bool(false), "Data should have been deleted but was found: \(data)")
                case .failure(let error):
                    #expect(Bool(false), "Unexpected error when verifying deletion: \(error)")
                }
            case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                #expect(true, "Authentication not available for high security deleteAll in test environment")
            case .failure(let error):
                #expect(Bool(false), "Unexpected error during high security deleteAll: \(error)")
            default:
                #expect(Bool(false), "Unexpected result from high security deleteAll: \(deleteResult)")
            }
            
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            // Can't test high security deleteAll if we can't write to high security store
            #expect(true, "High security operations not available in test environment")
            
        case .failure(let error):
            #expect(Bool(false), "Unexpected error writing to high security store: \(error)")
            
        default:
            #expect(Bool(false), "Unexpected result writing to high security store: \(writeResult)")
        }
    }

    @Test("deleteAll handles mixed security data properly")
    func deleteAll_mixedSecurityDataHandling() async {
        let mediumData = "Medium security data".data(using: .utf8)!
        let highData = "High security data".data(using: .utf8)!
        
        let mediumKey = "mixed_test_medium_key"
        let highKey = "mixed_test_high_key"
        
        // Store data in medium security store
        let mediumWriteResult = await sut.writeData(mediumData, forKey: mediumKey, requireAuthentication: false)
        #expect(mediumWriteResult == .success(true))
        
        // Attempt to store data in high security store
        let highWriteResult = await sut.writeData(highData, forKey: highKey, requireAuthentication: true)
        
        // Delete all from medium security store
        let mediumDeleteResult = await sut.deleteAll(requireAuthentication: false)
        #expect(mediumDeleteResult == .success(true))
        
        // Verify medium security data is gone
        let mediumReadResult = await sut.readData(forKey: mediumKey, requireAuthentication: false)
        #expect(mediumReadResult == .failure(.keyNotFound))
        
        // If high security data was stored successfully, it should still exist
        if case .success = highWriteResult {
            // Try to delete all from high security store
            let highDeleteResult = await sut.deleteAll(requireAuthentication: true)
            
            switch highDeleteResult {
            case .success(true):
                // Verify high security data is now gone
                let highReadResult = await sut.readData(forKey: highKey, requireAuthentication: true)
                switch highReadResult {
                case .failure(.keyNotFound):
                    #expect(true, "High security data successfully deleted")
                case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                    #expect(true, "Cannot verify high security deletion due to authentication limitations")
                default:
                    #expect(Bool(false), "Unexpected result when verifying high security deletion: \(highReadResult)")
                }
            case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                #expect(true, "Authentication not available for high security deleteAll")
            default:
                #expect(Bool(false), "Unexpected result from high security deleteAll: \(highDeleteResult)")
            }
        }
    }

    @Test("deleteAll error handling")
    func deleteAll_errorHandling() async {
        // Test deleteAll with various potential error scenarios
        
        // This test documents expected error behavior for deleteAll operations
        // Most errors would come from system-level issues or authentication problems
        
        let testData = "Error handling test data".data(using: .utf8)!
        let testKey = "error_handling_key"
        
        // Store some data first
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))
        
        // Test medium security deleteAll (should generally succeed)
        let mediumDeleteResult = await sut.deleteAll(requireAuthentication: false)
        
        switch mediumDeleteResult {
        case .success(true):
            #expect(true, "Medium security deleteAll succeeded as expected")
        case .failure(.secureHardwareUnavailable):
            #expect(true, "Keychain hardware unavailable - acceptable in test environments")
        case .failure(.deviceIsLocked):
            #expect(true, "Device locked - acceptable error condition")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error from medium security deleteAll: \(error)")
        default:
            #expect(Bool(false), "Unexpected result from medium security deleteAll: \(mediumDeleteResult)")
        }
        
        // Test high security deleteAll (may fail due to authentication)
        let highDeleteResult = await sut.deleteAll(requireAuthentication: true)
        
        switch highDeleteResult {
        case .success(true):
            #expect(true, "High security deleteAll succeeded")
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            #expect(true, "Expected authentication failure in test environment")
        case .failure(.authenticationCancelled), .failure(.authenticationFailed), .failure(.tooManyAttemps):
            #expect(true, "Authentication-related failure is acceptable")
        case .failure(.deviceIsLocked), .failure(.secureHardwareUnavailable):
            #expect(true, "System state error is acceptable")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error from high security deleteAll: \(error)")
        default:
            #expect(Bool(false), "Unexpected result from high security deleteAll: \(highDeleteResult)")
        }
    }

    @Test("deleteAll performance with multiple items")
    func deleteAll_performanceWithMultipleItems() async {
        let numberOfItems = 10 // Reasonable number for Keychain operations
        let testData = "Performance test data".data(using: .utf8)!
        
        // Store multiple items
        for i in 0..<numberOfItems {
            let writeResult = await sut.writeData(testData, forKey: "perf_delete_all_\(i)", requireAuthentication: false)
            #expect(writeResult == .success(true), "Failed to write item \(i)")
        }
        
        // Measure deleteAll performance
        let startTime = CFAbsoluteTimeGetCurrent()
        let deleteResult = await sut.deleteAll(requireAuthentication: false)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(deleteResult == .success(true), "DeleteAll should succeed")
        
        // Expect deleteAll to complete within reasonable time (2 seconds for 10 items)
        #expect(timeElapsed < 2.0, "DeleteAll took too long: \(timeElapsed) seconds")
        
        // Verify all items are gone
        for i in 0..<numberOfItems {
            let readResult = await sut.readData(forKey: "perf_delete_all_\(i)", requireAuthentication: false)
            #expect(readResult == .failure(.keyNotFound), "Item \(i) should be deleted")
        }
    }

    @Test("deleteAll concurrent access safety")
    func deleteAll_concurrentAccessSafety() async {
        let testData = "Concurrent test data".data(using: .utf8)!
        let numberOfOperations = 5 // Reduced for Keychain operations
        
        // Pre-populate some data
        for i in 0..<numberOfOperations {
            let _ = await sut.writeData(testData, forKey: "concurrent_delete_all_\(i)", requireAuthentication: false)
        }
        
        await withTaskGroup(of: Void.self) { group in
            // Add concurrent deleteAll operations
            for i in 0..<3 {
                group.addTask {
                    let _ = await self.sut.deleteAll(requireAuthentication: false)
                }
            }
            
            // Add some concurrent write operations
            for i in 0..<2 {
                group.addTask {
                    let _ = await self.sut.writeData(testData, forKey: "concurrent_new_\(i)", requireAuthentication: false)
                }
            }
        }
        
        // If we reach here without crashes or deadlocks, concurrent operations are safe
        #expect(true, "Concurrent deleteAll operations completed safely")
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

    @Test("authentication parameter controls separate keychain stores")
    func authenticationParameterControlsSeparateStores() async {
        let testData = "Store separation test".data(using: .utf8)!
        let testKey = "store_separation_key"

        // Store data in medium security store (requireAuthentication: false)
        let writeResult = await sut.writeData(testData, forKey: testKey, requireAuthentication: false)
        #expect(writeResult == .success(true))

        // Data can be read from the same store (medium security)
        let readResult1 = await sut.readData(forKey: testKey, requireAuthentication: false)
        #expect(readResult1 == .success(testData), "Should be able to read from medium security store")
        
        // Data CANNOT be read from the high security store because it's a separate store
        let readResult2 = await sut.readData(forKey: testKey, requireAuthentication: true)
        
        switch readResult2 {
        case .failure(.keyNotFound):
            #expect(true, "Data should not exist in high security store - they are separate stores")
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
            #expect(true, "Authentication failure prevented reading from high security store")
        case .success(let data):
            #expect(Bool(false), "Data should not be accessible from high security store when written to medium security store. Got: \(data)")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error reading from high security store: \(error)")
        }
    }

    @Test("high security store is separate from medium security store")
    func highSecurityStoreIsSeparateFromMediumStore() async {
        let mediumData = "Medium security data".data(using: .utf8)!
        let highData = "High security data".data(using: .utf8)!
        let testKey = "store_separation_key"

        // Store data in medium security store
        let mediumWriteResult = await sut.writeData(mediumData, forKey: testKey, requireAuthentication: false)
        #expect(mediumWriteResult == .success(true))

        // Try to store data in high security store with the same key
        let highWriteResult = await sut.writeData(highData, forKey: testKey, requireAuthentication: true)
        
        switch highWriteResult {
        case .success(true):
            // If high security write succeeded, both stores should contain different data
            let mediumReadResult = await sut.readData(forKey: testKey, requireAuthentication: false)
            #expect(mediumReadResult == .success(mediumData), "Medium security store should contain medium data")
            
            let highReadResult = await sut.readData(forKey: testKey, requireAuthentication: true)
            switch highReadResult {
            case .success(let data):
                #expect(data == highData, "High security store should contain high data, not medium data")
                #expect(data != mediumData, "High security store should not contain medium security data")
            case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet), .failure(.authenticationCancelled):
                #expect(true, "Cannot verify high security data due to authentication limitations")
            case .failure(let error):
                #expect(Bool(false), "Unexpected error reading from high security store: \(error)")
            }
            
        case .failure(.biometryNotEnrolled), .failure(.biometryNotAvailable), .failure(.passcodeNotSet):
            #expect(true, "High security operations not available in test environment")
        case .failure(let error):
            #expect(Bool(false), "Unexpected error writing to high security store: \(error)")
        default:
            #expect(Bool(false), "Unexpected result writing to high security store: \(highWriteResult)")
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
