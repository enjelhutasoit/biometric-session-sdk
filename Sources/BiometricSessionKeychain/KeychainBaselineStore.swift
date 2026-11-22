//
// Copyright (c) 2026 Enjel Hutasoit
//

import BiometricSessionCore
import Foundation
import Security

/// Keeps the enrollment baseline in the Keychain.
///
/// Public: pass it to `EnrollmentMonitor` as the store.
/// The item is NOT gated by biometry, so reading never shows a prompt.
/// It is readable only while the device is unlocked and stays on this device.
/// UNKNOWN: read behavior while the device is locked. Verify on DEVICE.
/// A failed checked read invalidates the monitored session.
/// Use a service and account that differ from `BiometricSecretStore`.
/// The same pair would overwrite the other item.
/// Client-side. A hooked process can read or replace the baseline.
public struct KeychainBaselineStore: EnrollmentBaselineStoring {
    private let key: KeychainItemKey
    private let client: any KeychainClient

    /// Creates a store for one item. Returns `nil` when `service` or `account` is empty.
    public init?(service: String, account: String) {
        self.init(service: service, account: account, client: SecItemClient())
    }

    // Internal: tests inject a fake client.
    init?(service: String, account: String, client: any KeychainClient) {
        guard let key = KeychainItemKey(service: service, account: account) else {
            return nil
        }
        self.key = key
        self.client = client
    }

    /// Returns the available baseline for clients using the original optional API.
    public func load() async -> DomainState? {
        try? await loadChecked()
    }

    /// Distinguishes a missing Keychain item from a read failure during session checks.
    public func loadChecked() async throws -> DomainState? {
        let result = client.read(key: key)
        if result.status == errSecItemNotFound { return nil }
        try KeychainStatusMapper.check(result.status)
        guard let data = result.data, let state = DomainState(data: data) else {
            throw BiometricSessionError(code: .keychainFailure)
        }
        return state
    }

    public func save(_ state: DomainState) async throws {
        let added = client.add(key: key, data: state.data)
        if added == errSecDuplicateItem {
            // Update keeps the old baseline if it fails.
            try KeychainStatusMapper.check(client.update(key: key, data: state.data))
        } else {
            try KeychainStatusMapper.check(added)
        }
    }

    public func clear() async throws {
        let status = client.delete(key: key)
        if status == errSecItemNotFound { return }
        try KeychainStatusMapper.check(status)
    }
}
