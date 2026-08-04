//
//  UserDefaultsStorageTests.swift
//  AMI-Production
//
//  Created by Assistant on 10/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

@testable import AMI_Staging
import Foundation
import Testing

@Suite("UserDefaultsStorage - Low-level storage operations")
struct UserDefaultsStorageTests {

    // MARK: - Test Configuration

    /// Unique test store identifier to isolate test data
    private static let testStoreID = "test_userdefaults_\(UUID().uuidString)"

    /// System under test - fresh instance for each test
    private var sut: UserDefaultsStorage {
        UserDefaultsStorage(for: Self.testStoreID)
    }

    // MARK: - Initialization Tests

    @Test("UserDefaultsStorage initializes successfully with valid store ID")
    func initialization_success() async {
        let storage = UserDefaultsStorage(for: "validStoreID")
        #expect(storage != nil)
    }

    @Test("UserDefaultsStorage creates isolated storage suites")
    func initialization_isolatedSuites() async {
        let storage1 = UserDefaultsStorage(for: "store1")
        let storage2 = UserDefaultsStorage(for: "store2")

        let testData = "test_data".data(using: .utf8)!
        let testKey = "isolation_test_key"

        // Store data in first storage
        let writeResult1 = await storage1.writeData(testData, forKey: testKey)
        #expect(writeResult1 == .success(true))

        // Verify data doesn't exist in second storage
        let readResult2 = await storage2.readData(forKey: testKey)
        #expect(readResult2 == .failure(.keyNotFound))

        // Verify data still exists in first storage
        let readResult1 = await storage1.readData(forKey: testKey)
        #expect(readResult1 == .success(testData))
    }

    // MARK: - Write Data Tests

    @Test("writeData stores binary data successfully")
    func writeData_success() async {
        let testData = "Hello, World!".data(using: .utf8)!
        let testKey = "write_test_key"

        let result = await sut.writeData(testData, forKey: testKey)

        #expect(result == .success(true))
    }

    @Test("writeData overwrites existing data")
    func writeData_overwrite() async {
        let testKey = "overwrite_test_key"
        let originalData = "Original Data".data(using: .utf8)!
        let newData = "New Data".data(using: .utf8)!

        // Store original data
        let writeResult1 = await sut.writeData(originalData, forKey: testKey)
        #expect(writeResult1 == .success(true))

        // Verify original data is stored
        let readResult1 = await sut.readData(forKey: testKey)
        #expect(readResult1 == .success(originalData))

        // Overwrite with new data
        let writeResult2 = await sut.writeData(newData, forKey: testKey)
        #expect(writeResult2 == .success(true))

        // Verify new data is stored
        let readResult2 = await sut.readData(forKey: testKey)
        #expect(readResult2 == .success(newData))
    }

    @Test("writeData handles empty data")
    func writeData_emptyData() async {
        let emptyData = Data()
        let testKey = "empty_data_key"

        let writeResult = await sut.writeData(emptyData, forKey: testKey)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey)
        #expect(readResult == .success(emptyData))
    }

    @Test("writeData handles large data")
    func writeData_largeData() async {
        // Create a 1MB data block
        let largeData = Data(repeating: 0xFF, count: 1024 * 1024)
        let testKey = "large_data_key"

        let writeResult = await sut.writeData(largeData, forKey: testKey)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey)
        #expect(readResult == .success(largeData))
    }

    @Test("writeData handles special characters in keys")
    func writeData_specialCharacterKeys() async {
        let testData = "test data".data(using: .utf8)!
        let specialKeys = [
            "key_with_underscores",
            "key-with-dashes",
            "key.with.dots",
            "key with spaces",
            "key@with#special$characters%",
            "keyWithUnicode🚀🎉",
            "keyWithNumbers123"
        ]

        for key in specialKeys {
            let writeResult = await sut.writeData(testData, forKey: key)
            #expect(writeResult == .success(true), "Failed to write data for key: \(key)")

            let readResult = await sut.readData(forKey: key)
            #expect(readResult == .success(testData), "Failed to read data for key: \(key)")
        }
    }

    // MARK: - Read Data Tests

    @Test("readData retrieves stored data successfully")
    func readData_success() async {
        let testData = "Test Data".data(using: .utf8)!
        let testKey = "read_test_key"

        // First store the data
        let writeResult = await sut.writeData(testData, forKey: testKey)
        #expect(writeResult == .success(true))

        // Then read it back
        let readResult = await sut.readData(forKey: testKey)
        #expect(readResult == .success(testData))
    }

    @Test("readData returns keyNotFound for non-existent key")
    func readData_keyNotFound() async {
        let result = await sut.readData(forKey: "non_existent_key")
        #expect(result == .failure(.keyNotFound))
    }

    @Test("readData returns typeMismatch for non-Data values")
    func readData_typeMismatch() async {
        let testKey = "type_mismatch_key"

        // Manually store a non-Data value directly in UserDefaults
        let suiteName = "\(AppBundle.identifier).\(Self.testStoreID)"
        if let userDefaults = UserDefaults(suiteName: suiteName) {
            userDefaults.set("This is a string, not Data", forKey: testKey)
        }

        let result = await sut.readData(forKey: testKey)

        switch result {
        case .failure(.typeMismatch):
            // This is expected
            #expect(true)
        default:
            #expect(Bool(false), "Expected typeMismatch error but got: \(result)")
        }
    }

    @Test("readData handles binary data correctly")
    func readData_binaryData() async {
        let binaryData = Data([0x00, 0x01, 0x02, 0xFF, 0xFE, 0xFD])
        let testKey = "binary_data_key"

        let writeResult = await sut.writeData(binaryData, forKey: testKey)
        #expect(writeResult == .success(true))

        let readResult = await sut.readData(forKey: testKey)
        #expect(readResult == .success(binaryData))
    }

    // MARK: - Delete Data Tests

    @Test("deleteData removes stored data successfully")
    func deleteData_success() async {
        let testData = "Data to delete".data(using: .utf8)!
        let testKey = "delete_test_key"

        // Store data
        let writeResult = await sut.writeData(testData, forKey: testKey)
        #expect(writeResult == .success(true))

        // Verify data exists
        let readResult1 = await sut.readData(forKey: testKey)
        #expect(readResult1 == .success(testData))

        // Delete data
        let deleteResult = await sut.deleteData(forKey: testKey)
        #expect(deleteResult == .success(true))

        // Verify data is gone
        let readResult2 = await sut.readData(forKey: testKey)
        #expect(readResult2 == .failure(.keyNotFound))
    }

    @Test("deleteData succeeds for non-existent key")
    func deleteData_nonExistentKey() async {
        let result = await sut.deleteData(forKey: "non_existent_key")
        #expect(result == .success(true))
    }

    @Test("deleteData only removes specified key")
    func deleteData_selectiveRemoval() async {
        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testKey1 = "selective_delete_key_1"
        let testKey2 = "selective_delete_key_2"

        // Store both pieces of data
        let writeResult1 = await sut.writeData(testData1, forKey: testKey1)
        let writeResult2 = await sut.writeData(testData2, forKey: testKey2)
        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))

        // Delete only the first key
        let deleteResult = await sut.deleteData(forKey: testKey1)
        #expect(deleteResult == .success(true))

        // Verify first key is deleted
        let readResult1 = await sut.readData(forKey: testKey1)
        #expect(readResult1 == .failure(.keyNotFound))

        // Verify second key still exists
        let readResult2 = await sut.readData(forKey: testKey2)
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

        // Store multiple pieces of data
        let writeResult1 = await sut.writeData(testData1, forKey: testKey1)
        let writeResult2 = await sut.writeData(testData2, forKey: testKey2)
        let writeResult3 = await sut.writeData(testData3, forKey: testKey3)

        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))
        #expect(writeResult3 == .success(true))

        // Verify all data exists
        let readResult1 = await sut.readData(forKey: testKey1)
        let readResult2 = await sut.readData(forKey: testKey2)
        let readResult3 = await sut.readData(forKey: testKey3)

        #expect(readResult1 == .success(testData1))
        #expect(readResult2 == .success(testData2))
        #expect(readResult3 == .success(testData3))

        // Delete all data
        let deleteAllResult = await sut.deleteAll()
        #expect(deleteAllResult == .success(true))

        // Verify all data is gone
        let readAfterDelete1 = await sut.readData(forKey: testKey1)
        let readAfterDelete2 = await sut.readData(forKey: testKey2)
        let readAfterDelete3 = await sut.readData(forKey: testKey3)

        #expect(readAfterDelete1 == .failure(.keyNotFound))
        #expect(readAfterDelete2 == .failure(.keyNotFound))
        #expect(readAfterDelete3 == .failure(.keyNotFound))
    }

    @Test("deleteAll succeeds on empty storage")
    func deleteAll_emptyStorage() async {
        let result = await sut.deleteAll()
        #expect(result == .success(true))
    }

    @Test("deleteAll only affects current storage suite")
    func deleteAll_isolatedToCurrentSuite() async {
        let storage1 = UserDefaultsStorage(for: "suite1")
        let storage2 = UserDefaultsStorage(for: "suite2")

        let testData1 = "Data 1".data(using: .utf8)!
        let testData2 = "Data 2".data(using: .utf8)!
        let testKey = "isolation_key"

        // Store data in both storages
        let writeResult1 = await storage1.writeData(testData1, forKey: testKey)
        let writeResult2 = await storage2.writeData(testData2, forKey: testKey)
        #expect(writeResult1 == .success(true))
        #expect(writeResult2 == .success(true))

        // Delete all from first storage
        let deleteAllResult = await storage1.deleteAll()
        #expect(deleteAllResult == .success(true))

        // Verify data is gone from first storage
        let readResult1 = await storage1.readData(forKey: testKey)
        #expect(readResult1 == .failure(.keyNotFound))

        // Verify data still exists in second storage
        let readResult2 = await storage2.readData(forKey: testKey)
        #expect(readResult2 == .success(testData2))
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
            let writeResult = await sut.writeData(jsonData, forKey: testKey)
            #expect(writeResult == .success(true))

            // Read JSON data back
            let readResult = await sut.readData(forKey: testKey)

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
        let numberOfOperations = 50

        await withTaskGroup(of: Void.self) { group in
            // Add concurrent write operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let data = "Data \(i)".data(using: .utf8)!
                    let _ = await self.sut.writeData(data, forKey: "\(testKey)_\(i)")
                }
            }

            // Add concurrent read operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let _ = await self.sut.readData(forKey: "\(testKey)_\(i)")
                }
            }

            // Add concurrent delete operations
            for i in 0..<numberOfOperations {
                group.addTask {
                    let _ = await self.sut.deleteData(forKey: "\(testKey)_\(i)")
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
        let numberOfOperations = 100

        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<numberOfOperations {
            let result = await sut.writeData(testData, forKey: "perf_write_\(i)")
            #expect(result == .success(true))
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Expect operations to complete within reasonable time (2 seconds for 100 operations)
        #expect(timeElapsed < 2.0, "Write operations took too long: \(timeElapsed) seconds")
    }

    @Test("performance of read operations")
    func performance_readOperations() async {
        let testData = "Performance test data".data(using: .utf8)!
        let numberOfOperations = 100

        // Pre-populate data
        for i in 0..<numberOfOperations {
            let _ = await sut.writeData(testData, forKey: "perf_read_\(i)")
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        for i in 0..<numberOfOperations {
            let result = await sut.readData(forKey: "perf_read_\(i)")
            #expect(result == .success(testData))
        }

        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        // Expect operations to complete within reasonable time (1 second for 100 operations)
        #expect(timeElapsed < 1.0, "Read operations took too long: \(timeElapsed) seconds")
    }

    // MARK: - Edge Cases

    @Test("storage works with various data sizes")
    func edgeCases_dataSizes() async {
        let testCases: [(String, Data)] = [
            ("single_byte", Data([0x01])),
            ("small_data", Data(repeating: 0xFF, count: 100)),
            ("medium_data", Data(repeating: 0xAA, count: 10_000)),
            ("large_data", Data(repeating: 0x55, count: 100_000))
        ]

        for (keyPrefix, testData) in testCases {
            let testKey = "\(keyPrefix)_size_test"

            let writeResult = await sut.writeData(testData, forKey: testKey)
            #expect(writeResult == .success(true), "Failed to write \(keyPrefix)")

            let readResult = await sut.readData(forKey: testKey)
            #expect(readResult == .success(testData), "Failed to read \(keyPrefix)")
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

            let writeResult = await sut.writeData(unicodeData, forKey: testKey)
            #expect(writeResult == .success(true), "Failed to write Unicode data for: \(unicodeString)")

            let readResult = await sut.readData(forKey: testKey)
            #expect(readResult == .success(unicodeData), "Failed to read Unicode data for: \(unicodeString)")

            // Verify the string round-trip
            if case .success(let retrievedData) = readResult {
                let retrievedString = String(data: retrievedData, encoding: .utf8)
                #expect(retrievedString == unicodeString, "Unicode string mismatch: expected \(unicodeString), got \(retrievedString ?? "nil")")
            }
        }
    }
}

// MARK: - Debug Description Tests

@Suite("UserDefaultsStorage - Debug Description")
struct UserDefaultsStorageDebugTests {

    @Test("debugDescription provides readable output")
    func debugDescription_format() async {
        let storage = UserDefaultsStorage(for: "debug_test")
        let debugOutput = storage.debugDescription

        // Should be a non-empty string (even if no data is stored, it should show empty dict)
        #expect(!debugOutput.isEmpty)

        // Should contain dictionary-like formatting
        #expect(debugOutput.contains("{") || debugOutput.contains("["))
    }

    @Test("debugDescription includes stored data")
    func debugDescription_includesStoredData() async {
        let storage = UserDefaultsStorage(for: "debug_with_data_test")
        let testData = "Debug test data".data(using: .utf8)!
        let testKey = "debug_test_key"

        // Store some data
        let writeResult = await storage.writeData(testData, forKey: testKey)
        #expect(writeResult == .success(true))

        let debugOutput = storage.debugDescription

        // Should contain the key we stored (UserDefaults stores Data as base64 or similar)
        #expect(debugOutput.contains(testKey), "Debug output should contain the stored key")
    }
}

// swiftformat:enable all
// swiftlint:enable all
