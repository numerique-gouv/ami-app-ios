//
//  DeviceIDProvider.swift
//  AMI-Preproduction
//
//  Created by Nicolas Buquet on 02/11/2026.
//  Copyright © 2026 DINUM. All rights reserved.
//

import Foundation

/// Defines the interface for managing the application's device identifier.
///
/// The device identifier is a unique value identifying this application
/// installation on the current device. The backend correlates it with the
/// user account to maintain per-device state — notably the push-notification
/// consent.
///
/// ## Architecture Role
/// This protocol is the Domain-layer port of the DeviceID feature. It
/// abstracts the persistence mechanism (e.g. encrypted local storage) behind
/// a storage-agnostic interface: other features and services depend on this
/// port, never on a concrete implementation.
///
/// The protocol is `nonisolated`: conforming types may isolate their state as
/// they see fit (e.g. behind an `actor`), while clients only ever interact
/// with the existential through its async operations.
///
/// ## Identifier Lifecycle
/// - **Retrieval**: `getOrCreateDeviceID()` returns the current identifier,
///   generating and persisting one when none exists yet. The identifier is
///   stable across calls and app relaunches for the lifetime of the
///   installation.
/// - **Ephemeral fallback**: when the backing storage is unavailable (e.g. the
///   device is locked), the implementation may serve an *ephemeral* identifier
///   that is not persisted. Ephemeral identifiers are stable within the
///   current process only and change between app launches.
/// - **Invalidation**: `resetDeviceID(onReset:)` marks the stored identifier
///   as invalidated. The replacement is *deferred*: a fresh identifier is
///   generated and persisted by the next `getOrCreateDeviceID()` call.
///
///   Invalidation exists because secure storage may survive app
///   uninstallation: after a reinstall, the stale identifier would remain
///   bound on the backend to the previous installation's push-notification
///   consent, so the consent flow would never be re-proposed to the user.
///   Invoking the reset at first launch since (re)installation restores a
///   consistent state.
///
/// ## Reset Completion Contract
/// The `onReset` action passed to `resetDeviceID(onReset:)` is invoked at the
/// moment the replacement identifier is actually persisted:
/// - **at most once** — the action is consumed upon invocation;
/// - **possibly never** — the app may terminate before the reset completes, or
///   the device may be unable to persist at all; the reset then simply
///   re-triggers on a later access, which is the correct behavior;
/// - **last call wins** — registering a new action while a reset is pending
///   discards the previously registered one.
nonisolated protocol DeviceIDProvider {
    /// The reset device ID completion action type
    typealias ResetDeviceIDCompletionAction = @Sendable () async -> Void

    /// Retrieves the current device identifier, or generates and persists a
    /// new one if none exists yet.
    ///
    /// - Returns: The current device identifier. Always a usable value; it may
    ///   be ephemeral (not persisted) when the backing storage is unavailable.
    func getOrCreateDeviceID() async -> DeviceID

    /// Marks the current device identifier as invalidated and registers
    /// `onReset`, invoked once the replacement identifier has been persisted.
    ///
    /// The reset is deferred: this method performs no storage I/O itself; the
    /// new identifier is created by the next `getOrCreateDeviceID()` call.
    ///
    /// - Parameter onReset: Action invoked at most once, when the replacement
    ///   identifier is persisted (see the Reset Completion Contract above).
    func resetDeviceID(onReset: @escaping ResetDeviceIDCompletionAction) async
}
