//
//  DeviceIDTests.swift
//  AMI-UnitTests
//
//  Created by Nicolas Buquet on 29/10/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

// swiftlint:disable all
// swiftformat:disable all

import Foundation
import Testing

@testable import AMI_Staging

@Suite("DeviceID - Device identifier management")
struct DeviceIDTests {

    // MARK: - Test Configuration

    /// The key used by `DeviceID` to persist the ID.
    /// Must stay in sync with `DeviceID.DEVICE_ID_KEY`.
    private static let deviceIDKey = "deviceID"

    // MARK: - Helpers

    /// Builds a system under test backed by an in-memory storage fake.
    private func makeSUT(storeName: String = "test") -> (DeviceID, FakeLocalStorage) {
        let storage = FakeLocalStorage(for: storeName)
        let sut = DeviceID(localStorageName: storeName) { _ in storage }
        return (sut, storage)
    }

    /// Reads the value currently persisted in the fake storage.
    private func storedValue(in storage: FakeLocalStorage) async -> String? {
        switch await storage.readString(key: Self.deviceIDKey, secureLevel: .encrypted) {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    // MARK: - getOrCreateDeviceID

    @Test("generates and persists a new UUID on first call")
    func getOrCreate_generatesAndPersistsOnFirstCall() async {
        let (sut, storage) = makeSUT()

        let deviceID = await sut.getOrCreateDeviceID()

        #expect(UUID(uuidString: deviceID) != nil)
        #expect(await storedValue(in: storage) == deviceID)
    }

    @Test("persists and reads the device ID at the encrypted secure level")
    func getOrCreate_usesEncryptedSecureLevel() async {
        let (sut, storage) = makeSUT()

        _ = await sut.getOrCreateDeviceID()

        #expect(await storage.lastReadSecureLevel == .encrypted)
        #expect(await storage.lastWriteSecureLevel == .encrypted)
    }

    @Test("returns the same ID across repeated calls without rewriting storage")
    func getOrCreate_stableAcrossCalls() async {
        let (sut, storage) = makeSUT()

        let first = await sut.getOrCreateDeviceID()
        let second = await sut.getOrCreateDeviceID()
        let third = await sut.getOrCreateDeviceID()

        #expect(first == second)
        #expect(second == third)
        #expect(await storage.writeStringCalls == 1)
    }

    @Test("serves an existing stored ID without regenerating it")
    func getOrCreate_servesStoredID() async {
        let (sut, storage) = makeSUT()
        let storedID = UUID().uuidString
        await storage.seed(storedID, forKey: Self.deviceIDKey)

        let deviceID = await sut.getOrCreateDeviceID()

        #expect(deviceID == storedID)
        #expect(await storage.writeStringCalls == 0)
    }

    @Test("regenerates a new ID when the stored value is unreadable")
    func getOrCreate_regeneratesOnTypeMismatch() async {
        let (sut, storage) = makeSUT()
        await storage.setReadError(.typeMismatch(nil))

        let deviceID = await sut.getOrCreateDeviceID()

        #expect(UUID(uuidString: deviceID) != nil)
        await storage.setReadError(nil)
        #expect(await storedValue(in: storage) == deviceID)
    }

    @Test("serves a stable cached ID while storage is unavailable")
    func getOrCreate_servesStableCachedIDWhileStorageDown() async {
        let (sut, storage) = makeSUT()
        let originalID = UUID().uuidString
        await storage.seed(originalID, forKey: Self.deviceIDKey)
        await storage.setReadError(.deviceIsLocked)
        await storage.setWriteError(.deviceIsLocked)

        let first = await sut.getOrCreateDeviceID()
        let second = await sut.getOrCreateDeviceID()

        #expect(UUID(uuidString: first) != nil)
        #expect(first != originalID)
        #expect(first == second)

        // The cached ID is never persisted while writes fail: the stored ID is untouched.
        await storage.setReadError(nil)
        #expect(await storedValue(in: storage) == originalID)
    }

    @Test("serves the stored ID again once storage becomes available")
    func getOrCreate_servesStoredIDAgainWhenStorageRecovers() async {
        let (sut, storage) = makeSUT()
        let originalID = UUID().uuidString
        await storage.seed(originalID, forKey: Self.deviceIDKey)
        await storage.setReadError(.deviceIsLocked)
        await storage.setWriteError(.deviceIsLocked)

        let cachedID = await sut.getOrCreateDeviceID()
        #expect(cachedID != originalID)

        await storage.setReadError(nil)
        await storage.setWriteError(nil)

        // Persistent storage wins over the in-memory cache once available again.
        #expect(await sut.getOrCreateDeviceID() == originalID)
    }

    @Test("a fresh instance with the same storage serves the stored ID")
    func getOrCreate_persistedAcrossInstances() async {
        let storage = FakeLocalStorage(for: "test")
        let sut1 = DeviceID(localStorageName: "test") { _ in storage }
        let sut2 = DeviceID(localStorageName: "test") { _ in storage }

        let fromFirst = await sut1.getOrCreateDeviceID()

        #expect(await sut2.getOrCreateDeviceID() == fromFirst)
    }

    @Test("uses the injected storage name")
    func getOrCreate_usesInjectedStorageName() async {
        let (sut, storage) = makeSUT(storeName: "custom-store")

        _ = await sut.getOrCreateDeviceID()

        #expect(await storage.initializedStoreName == "custom-store")
    }

    // MARK: - resetDeviceID

    @Test("reset replaces the stored ID and invokes the completion once")
    func reset_replacesStoredIDAndInvokesCompletionOnce() async {
        let (sut, storage) = makeSUT()
        let originalID = UUID().uuidString
        await storage.seed(originalID, forKey: Self.deviceIDKey)
        let calls = CallCounter()

        await sut.resetDeviceID { calls.increment() }
        let newID = await sut.getOrCreateDeviceID()

        #expect(newID != originalID)
        #expect(calls.value == 1)
        #expect(await storedValue(in: storage) == newID)

        // The completion is consumed: later calls keep the ID without re-invoking it.
        #expect(await sut.getOrCreateDeviceID() == newID)
        #expect(calls.value == 1)
    }

    @Test("reset works when no ID is stored yet (first launch)")
    func reset_worksOnFirstLaunch() async {
        let (sut, storage) = makeSUT()
        let calls = CallCounter()

        await sut.resetDeviceID { calls.increment() }
        let deviceID = await sut.getOrCreateDeviceID()

        #expect(UUID(uuidString: deviceID) != nil)
        #expect(await storedValue(in: storage) == deviceID)
        #expect(calls.value == 1)
    }

    @Test("reset retries on every access until persistence succeeds")
    func reset_retriesUntilPersistenceSucceeds() async {
        let (sut, storage) = makeSUT()
        let originalID = UUID().uuidString
        await storage.seed(originalID, forKey: Self.deviceIDKey)
        await storage.setWriteError(.deviceIsLocked)
        let calls = CallCounter()

        await sut.resetDeviceID { calls.increment() }

        // While writes fail: a fresh cached ID is served — stable across calls,
        // never the stale stored one — and the completion is not fired.
        let first = await sut.getOrCreateDeviceID()
        #expect(first != originalID)
        #expect(await sut.getOrCreateDeviceID() == first)
        #expect(calls.value == 0)
        #expect(await storedValueRaw(in: storage) == originalID)

        // Once storage recovers, the cached ID becomes the persisted one
        // and the completion is invoked exactly then.
        await storage.setWriteError(nil)

        #expect(await sut.getOrCreateDeviceID() == first)
        #expect(calls.value == 1)
        #expect(await storedValueRaw(in: storage) == first)
    }

    /// Reads the raw persisted value without going through the (possibly erroring) read path.
    private func storedValueRaw(in storage: FakeLocalStorage) async -> String? {
        await storage.rawValue(forKey: Self.deviceIDKey)
    }

    @Test("reset skips the storage read entirely while pending")
    func reset_skipsStorageReadWhilePending() async {
        let (sut, storage) = makeSUT()
        await storage.seed(UUID().uuidString, forKey: Self.deviceIDKey)
        await storage.setWriteError(.deviceIsLocked)

        await sut.resetDeviceID { }
        _ = await sut.getOrCreateDeviceID()

        #expect(await storage.readStringCalls == 0)
    }

    @Test("re-registering a completion while pending keeps only the last one")
    func reset_lastRegisteredCompletionWins() async {
        let (sut, storage) = makeSUT()
        await storage.seed(UUID().uuidString, forKey: Self.deviceIDKey)
        let firstCalls = CallCounter()
        let secondCalls = CallCounter()

        await sut.resetDeviceID { firstCalls.increment() }
        await sut.resetDeviceID { secondCalls.increment() }
        let newID = await sut.getOrCreateDeviceID()

        #expect(UUID(uuidString: newID) != nil)
        #expect(firstCalls.value == 0)
        #expect(secondCalls.value == 1)
    }

    @Test("successive reset cycles each produce a fresh ID")
    func reset_successiveCyclesProduceFreshIDs() async {
        let (sut, storage) = makeSUT()
        let idA = await sut.getOrCreateDeviceID()

        let cycle1 = CallCounter()
        await sut.resetDeviceID { cycle1.increment() }
        let idB = await sut.getOrCreateDeviceID()

        let cycle2 = CallCounter()
        await sut.resetDeviceID { cycle2.increment() }
        let idC = await sut.getOrCreateDeviceID()

        #expect(idB != idA)
        #expect(idC != idB)
        #expect(cycle1.value == 1)
        #expect(cycle2.value == 1)
        #expect(await storedValue(in: storage) == idC)
    }

    @Test("concurrent calls during a pending reset converge on a single ID")
    func reset_concurrentCallsConvergeOnSingleID() async {
        let (sut, storage) = makeSUT()
        // Keep writes in flight long enough for the concurrent
        // `getOrCreateDeviceID` calls to interleave at the suspension point.
        await storage.setWriteSuspension(.milliseconds(50))
        let calls = CallCounter()

        await sut.resetDeviceID { calls.increment() }

        async let id1 = sut.getOrCreateDeviceID()
        async let id2 = sut.getOrCreateDeviceID()
        async let id3 = sut.getOrCreateDeviceID()

        let ids = await [id1, id2, id3]

        #expect(Set(ids).count == 1)
        #expect(calls.value == 1)
        #expect(await storedValueRaw(in: storage) == ids[0])
    }
}

// MARK: - Test Doubles

/// A lock-protected counter that can be captured by the `@Sendable` reset completion action.
private final class CallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    var value: Int {
        lock.withLock { count }
    }

    func increment() {
        lock.withLock { count += 1 }
    }
}

/// In-memory fake of `LocalStorageRepositoryProtocol` for hermetic testing.
///
/// `DeviceID` only exercises `readString`/`writeString`; the other requirements
/// are minimal stubs.
private actor FakeLocalStorage: LocalStorageRepositoryProtocol {

    // MARK: Test hooks

    var readError: LocalStorageErrorType?
    var writeError: LocalStorageErrorType?
    /// Artificial delay applied on writes, to force concurrent calls to interleave.
    var writeSuspension: Duration = .zero

    // MARK: Observations

    private(set) var readStringCalls = 0
    private(set) var writeStringCalls = 0
    private(set) var lastReadSecureLevel: LocalStorageSecureLevelType?
    private(set) var lastWriteSecureLevel: LocalStorageSecureLevelType?
    private(set) var initializedStoreName: String?

    // MARK: Storage

    private var store: [String: String] = [:]

    // MARK: LocalStorageRepositoryProtocol

    init(for userStoreID: String) {
        initializedStoreName = userStoreID
    }

    func writeString(key: String, value: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        writeStringCalls += 1
        lastWriteSecureLevel = secureLevel
        if writeSuspension > .zero {
            try? await Task.sleep(for: writeSuspension)
        }
        if let writeError {
            return .failure(writeError)
        }
        store[key] = value
        return .success(true)
    }

    func readString(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<String, LocalStorageErrorType> {
        readStringCalls += 1
        lastReadSecureLevel = secureLevel
        if let readError {
            return .failure(readError)
        }
        guard let value = store[key] else {
            return .failure(.keyNotFound)
        }
        return .success(value)
    }

    // MARK: Unused by DeviceID — minimal stubs

    func writeBool(key: String, value: Bool, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        .success(true)
    }

    func writeInt(key: String, value: Int, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        .success(true)
    }

    func readBool(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        .failure(.keyNotFound)
    }

    func readInt(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Int, LocalStorageErrorType> {
        .failure(.keyNotFound)
    }

    func delete(key: String, secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        store.removeValue(forKey: key)
        return .success(true)
    }

    func deleteAll(secureLevel: LocalStorageSecureLevelType) async -> Result<Bool, LocalStorageErrorType> {
        store.removeAll()
        return .success(true)
    }

    // MARK: Test helpers

    /// Seeds the storage directly, bypassing the protocol method and its
    /// call counters, to simulate a value persisted by a previous launch.
    func seed(_ value: String, forKey key: String) {
        store[key] = value
    }

    /// Reads the raw stored value without going through the (possibly erroring) read path.
    func rawValue(forKey key: String) -> String? {
        store[key]
    }

    func setReadError(_ error: LocalStorageErrorType?) {
        readError = error
    }

    func setWriteError(_ error: LocalStorageErrorType?) {
        writeError = error
    }

    func setWriteSuspension(_ duration: Duration) {
        writeSuspension = duration
    }
}

// swiftformat:enable all
// swiftlint:enable all
