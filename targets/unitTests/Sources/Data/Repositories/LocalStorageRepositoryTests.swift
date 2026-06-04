//
//  LocalStorageRepositoryTests.swift
//  AMI-Production
//
//  Created by Nicolas Buquet on 03/06/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

@testable import AMI_Staging
import Foundation
import Testing

// MARK: - Low secure level (UserDefaults)

@Suite("LocalStorageRepository - Low secure level (UserDefaults)")
struct LocalStorageRepositoryLowTests {
    var sut: LocalStorageRepositoryProtocolMock

    init() {
        sut = LocalStorageRepositoryProtocolMock()
    }

    // MARK: - Write

    @Test("writeBool stores a Bool value successfully")
    func writeBool_success() async {
        sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeBool(key: "bool_key", value: true, secureLevel: .low)
        #expect(result == .success(true))
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "bool_key")
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.value == true)
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("writeBool fails with writeFailed error")
    func writeBool_writeFailed() async {
        sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.writeFailed)
        let result = await sut.writeBool(key: "bool_key", value: true, secureLevel: .low)
        #expect(result == .failure(.writeFailed))
    }

    @Test("writeInt stores an Int value successfully")
    func writeInt_success() async {
        sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeInt(key: "int_key", value: 42, secureLevel: .low)
        #expect(result == .success(true))
        #expect(sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "int_key")
        #expect(sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.value == 42)
        #expect(sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("writeInt fails with writeFailed error")
    func writeInt_writeFailed() async {
        sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.writeFailed)
        let result = await sut.writeInt(key: "int_key", value: 42, secureLevel: .low)
        #expect(result == .failure(.writeFailed))
    }

    @Test("writeString stores a String value successfully")
    func writeString_success() async {
        sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeString(key: "string_key", value: "hello", secureLevel: .low)
        #expect(result == .success(true))
        #expect(sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "string_key")
        #expect(sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.value == "hello")
        #expect(sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("writeString fails with writeFailed error")
    func writeString_writeFailed() async {
        sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.writeFailed)
        let result = await sut.writeString(key: "string_key", value: "hello", secureLevel: .low)
        #expect(result == .failure(.writeFailed))
    }

    // MARK: - Read

    @Test("readBool retrieves a stored Bool value successfully")
    func readBool_success() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.readBool(key: "bool_key", secureLevel: .low)
        #expect(result == .success(true))
        #expect(sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "bool_key")
        #expect(sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("readBool fails with keyNotFound error")
    func readBool_keyNotFound() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.keyNotFound)
        let result = await sut.readBool(key: "missing_key", secureLevel: .low)
        #expect(result == .failure(.keyNotFound))
    }

    @Test("readBool fails with typeMismatch error")
    func readBool_typeMismatch() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.typeMismatch(NSError()))
        let result = await sut.readBool(key: "bool_key", secureLevel: .low)
        #expect(result == .failure(.typeMismatch(NSError())))
    }

    @Test("readInt retrieves a stored Int value successfully")
    func readInt_success() async {
        sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue = .success(42)
        let result = await sut.readInt(key: "int_key", secureLevel: .low)
        #expect(result == .success(42))
        #expect(sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeCalled)
        #expect(sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedArguments?.key == "int_key")
        #expect(sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("readInt fails with keyNotFound error")
    func readInt_keyNotFound() async {
        sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue = .failure(.keyNotFound)
        let result = await sut.readInt(key: "missing_key", secureLevel: .low)
        #expect(result == .failure(.keyNotFound))
    }

    @Test("readInt fails with typeMismatch error")
    func readInt_typeMismatch() async {
        sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue = .failure(.typeMismatch(NSError()))
        let result = await sut.readInt(key: "int_key", secureLevel: .low)
        #expect(result == .failure(.typeMismatch(NSError())))
    }

    @Test("readString retrieves a stored String value successfully")
    func readString_success() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .success("hello")
        let result = await sut.readString(key: "string_key", secureLevel: .low)
        #expect(result == .success("hello"))
        #expect(sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeCalled)
        #expect(sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedArguments?.key == "string_key")
        #expect(sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("readString fails with keyNotFound error")
    func readString_keyNotFound() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .failure(.keyNotFound)
        let result = await sut.readString(key: "missing_key", secureLevel: .low)
        #expect(result == .failure(.keyNotFound))
    }

    @Test("readString fails with typeMismatch error")
    func readString_typeMismatch() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .failure(.typeMismatch(NSError()))
        let result = await sut.readString(key: "string_key", secureLevel: .low)
        #expect(result == .failure(.typeMismatch(NSError())))
    }

    // MARK: - Delete

    @Test("delete removes a value successfully")
    func delete_success() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.delete(key: "bool_key", secureLevel: .low)
        #expect(result == .success(true))
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "bool_key")
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .low)
    }

    @Test("delete fails with deleteFailed error")
    func delete_deleteFailed() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.deleteFailed)
        let result = await sut.delete(key: "bool_key", secureLevel: .low)
        #expect(result == .failure(.deleteFailed))
    }

    @Test("delete fails with keyNotFound error")
    func delete_keyNotFound() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.keyNotFound)
        let result = await sut.delete(key: "missing_key", secureLevel: .low)
        #expect(result == .failure(.keyNotFound))
    }
}

// MARK: - Medium secure level (Keychain)

@Suite("LocalStorageRepository - Medium secure level (Keychain)")
struct LocalStorageRepositoryMediumTests {
    var sut: LocalStorageRepositoryProtocolMock

    init() {
        sut = LocalStorageRepositoryProtocolMock()
    }

    // MARK: - Write

    @Test("writeBool stores a Bool value successfully via Keychain")
    func writeBool_success() async {
        sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeBool(key: "bool_key", value: true, secureLevel: .medium)
        #expect(result == .success(true))
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "bool_key")
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.value == true)
        #expect(sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("writeBool fails with encryptionFailed error")
    func writeBool_encryptionFailed() async {
        sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.encryptionFailed)
        let result = await sut.writeBool(key: "bool_key", value: true, secureLevel: .medium)
        #expect(result == .failure(.encryptionFailed))
    }

    @Test("writeBool fails with secureHardwareUnavailable error")
    func writeBool_secureHardwareUnavailable() async {
        sut.writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.secureHardwareUnavailable)
        let result = await sut.writeBool(key: "bool_key", value: true, secureLevel: .medium)
        #expect(result == .failure(.secureHardwareUnavailable))
    }

    @Test("writeInt stores an Int value successfully via Keychain")
    func writeInt_success() async {
        sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeInt(key: "int_key", value: 42, secureLevel: .medium)
        #expect(result == .success(true))
        #expect(sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("writeInt fails with writeFailed error")
    func writeInt_writeFailed() async {
        sut.writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.writeFailed)
        let result = await sut.writeInt(key: "int_key", value: 42, secureLevel: .medium)
        #expect(result == .failure(.writeFailed))
    }

    @Test("writeString stores a String value successfully via Keychain")
    func writeString_success() async {
        sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.writeString(key: "string_key", value: "secret", secureLevel: .medium)
        #expect(result == .success(true))
        #expect(sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("writeString fails with writeFailed error")
    func writeString_writeFailed() async {
        sut.writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.writeFailed)
        let result = await sut.writeString(key: "string_key", value: "secret", secureLevel: .medium)
        #expect(result == .failure(.writeFailed))
    }

    // MARK: - Read

    @Test("readBool retrieves a stored Bool value successfully from Keychain")
    func readBool_success() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.readBool(key: "bool_key", secureLevel: .medium)
        #expect(result == .success(true))
        #expect(sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("readBool fails with decryptionFailed error")
    func readBool_decryptionFailed() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.decryptionFailed)
        let result = await sut.readBool(key: "bool_key", secureLevel: .medium)
        #expect(result == .failure(.decryptionFailed))
    }

    @Test("readBool fails with secureHardwareUnavailable error")
    func readBool_secureHardwareUnavailable() async {
        sut.readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.secureHardwareUnavailable)
        let result = await sut.readBool(key: "bool_key", secureLevel: .medium)
        #expect(result == .failure(.secureHardwareUnavailable))
    }

    @Test("readInt retrieves a stored Int value successfully from Keychain")
    func readInt_success() async {
        sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue = .success(42)
        let result = await sut.readInt(key: "int_key", secureLevel: .medium)
        #expect(result == .success(42))
        #expect(sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("readInt fails with decryptionFailed error")
    func readInt_decryptionFailed() async {
        sut.readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue = .failure(.decryptionFailed)
        let result = await sut.readInt(key: "int_key", secureLevel: .medium)
        #expect(result == .failure(.decryptionFailed))
    }

    @Test("readString retrieves a stored String value successfully from Keychain")
    func readString_success() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .success("secret")
        let result = await sut.readString(key: "string_key", secureLevel: .medium)
        #expect(result == .success("secret"))
        #expect(sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("readString fails with decryptionFailed error")
    func readString_decryptionFailed() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .failure(.decryptionFailed)
        let result = await sut.readString(key: "string_key", secureLevel: .medium)
        #expect(result == .failure(.decryptionFailed))
    }

    @Test("readString fails with secureHardwareUnavailable error")
    func readString_secureHardwareUnavailable() async {
        sut.readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue = .failure(.secureHardwareUnavailable)
        let result = await sut.readString(key: "string_key", secureLevel: .medium)
        #expect(result == .failure(.secureHardwareUnavailable))
    }

    // MARK: - Delete

    @Test("delete removes a Keychain value successfully")
    func delete_success() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .success(true)
        let result = await sut.delete(key: "string_key", secureLevel: .medium)
        #expect(result == .success(true))
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled)
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.key == "string_key")
        #expect(sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments?.secureLevel == .medium)
    }

    @Test("delete fails with deleteFailed error")
    func delete_deleteFailed() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.deleteFailed)
        let result = await sut.delete(key: "string_key", secureLevel: .medium)
        #expect(result == .failure(.deleteFailed))
    }

    @Test("delete fails with secureHardwareUnavailable error")
    func delete_secureHardwareUnavailable() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.secureHardwareUnavailable)
        let result = await sut.delete(key: "string_key", secureLevel: .medium)
        #expect(result == .failure(.secureHardwareUnavailable))
    }

    @Test("delete fails with keyNotFound error")
    func delete_keyNotFound() async {
        sut.deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue = .failure(.keyNotFound)
        let result = await sut.delete(key: "missing_key", secureLevel: .medium)
        #expect(result == .failure(.keyNotFound))
    }
}
