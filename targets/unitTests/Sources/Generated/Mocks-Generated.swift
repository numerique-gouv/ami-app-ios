// Generated using Sourcery 2.2.6 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable all

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Foundation

























class LocalStorageRepositoryProtocolMock: LocalStorageRepositoryProtocol {




    //MARK: - writeBool

    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount = 0
    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled: Bool {
        return writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount > 0
    }
    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments: (key: String, value: Bool, secureLevel: LocalStorageSecureLevelType)?
    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations: [(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType)] = []
    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue: Result<Bool, LocalStorageErrorType>!
    var writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure: ((String, Bool, LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>)?

    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount += 1
        writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments = (key: key, value: value, secureLevel: secureLevel)
        writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations.append((key: key, value: value, secureLevel: secureLevel))
        if let writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure = writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure {
            return await writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure(key, value, secureLevel)
        } else {
            return writeBoolKeyStringValueBoolSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - writeInt

    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount = 0
    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled: Bool {
        return writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount > 0
    }
    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments: (key: String, value: Int, secureLevel: LocalStorageSecureLevelType)?
    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations: [(key: String, value: Int, secureLevel: LocalStorageSecureLevelType)] = []
    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue: Result<Bool, LocalStorageErrorType>!
    var writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure: ((String, Int, LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>)?

    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount += 1
        writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments = (key: key, value: value, secureLevel: secureLevel)
        writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations.append((key: key, value: value, secureLevel: secureLevel))
        if let writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure = writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure {
            return await writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure(key, value, secureLevel)
        } else {
            return writeIntKeyStringValueIntSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - writeString

    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount = 0
    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled: Bool {
        return writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount > 0
    }
    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments: (key: String, value: String, secureLevel: LocalStorageSecureLevelType)?
    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations: [(key: String, value: String, secureLevel: LocalStorageSecureLevelType)] = []
    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue: Result<Bool, LocalStorageErrorType>!
    var writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure: ((String, String, LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>)?

    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount += 1
        writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments = (key: key, value: value, secureLevel: secureLevel)
        writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations.append((key: key, value: value, secureLevel: secureLevel))
        if let writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure = writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure {
            return await writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure(key, value, secureLevel)
        } else {
            return writeStringKeyStringValueStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - readBool

    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount = 0
    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled: Bool {
        return readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount > 0
    }
    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments: (key: String, secureLevel: LocalStorageSecureLevelType)?
    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations: [(key: String, secureLevel: LocalStorageSecureLevelType)] = []
    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue: Result<Bool, LocalStorageErrorType>!
    var readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure: ((String, LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>)?

    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount += 1
        readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments = (key: key, secureLevel: secureLevel)
        readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations.append((key: key, secureLevel: secureLevel))
        if let readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure = readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure {
            return await readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure(key, secureLevel)
        } else {
            return readBoolKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - readInt

    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeCallsCount = 0
    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeCalled: Bool {
        return readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeCallsCount > 0
    }
    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedArguments: (key: String, secureLevel: LocalStorageSecureLevelType)?
    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedInvocations: [(key: String, secureLevel: LocalStorageSecureLevelType)] = []
    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue: Result<Int, LocalStorageErrorType>!
    var readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeClosure: ((String, LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType>)?

    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType> {
        readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeCallsCount += 1
        readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedArguments = (key: key, secureLevel: secureLevel)
        readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReceivedInvocations.append((key: key, secureLevel: secureLevel))
        if let readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeClosure = readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeClosure {
            return await readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeClosure(key, secureLevel)
        } else {
            return readIntKeyStringSecureLevelLocalStorageSecureLevelTypeResultIntLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - readString

    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeCallsCount = 0
    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeCalled: Bool {
        return readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeCallsCount > 0
    }
    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedArguments: (key: String, secureLevel: LocalStorageSecureLevelType)?
    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedInvocations: [(key: String, secureLevel: LocalStorageSecureLevelType)] = []
    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue: Result<String, LocalStorageErrorType>!
    var readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeClosure: ((String, LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType>)?

    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType> {
        readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeCallsCount += 1
        readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedArguments = (key: key, secureLevel: secureLevel)
        readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReceivedInvocations.append((key: key, secureLevel: secureLevel))
        if let readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeClosure = readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeClosure {
            return await readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeClosure(key, secureLevel)
        } else {
            return readStringKeyStringSecureLevelLocalStorageSecureLevelTypeResultStringLocalStorageErrorTypeReturnValue
        }
    }

    //MARK: - delete

    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount = 0
    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCalled: Bool {
        return deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount > 0
    }
    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments: (key: String, secureLevel: LocalStorageSecureLevelType)?
    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations: [(key: String, secureLevel: LocalStorageSecureLevelType)] = []
    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue: Result<Bool, LocalStorageErrorType>!
    var deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure: ((String, LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType>)?

    func delete(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeCallsCount += 1
        deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedArguments = (key: key, secureLevel: secureLevel)
        deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReceivedInvocations.append((key: key, secureLevel: secureLevel))
        if let deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure = deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure {
            return await deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeClosure(key, secureLevel)
        } else {
            return deleteKeyStringSecureLevelLocalStorageSecureLevelTypeResultBoolLocalStorageErrorTypeReturnValue
        }
    }


}
// swiftlint:enable all