//
// Copyright (c) 2026 Enjel Hutasoit
//

/// Keeps the enrollment fingerprint seen at sign in.
///
/// Public: the Keychain adapter (another module) and client code conform to it.
/// The baseline must survive app restarts, or every launch looks like a change.
/// Reading must not show a prompt.
public protocol EnrollmentBaselineStoring: Sendable {
    /// The saved baseline. `nil` when none exists or it cannot be read.
    func load() async -> DomainState?
    /// Reads the baseline for a session check. Return nil only for confirmed absence.
    /// Throw when the store cannot determine whether a baseline exists.
    func loadChecked() async throws -> DomainState?
    /// Replaces the baseline.
    func save(_ state: DomainState) async throws
    /// Removes the baseline.
    func clear() async throws
}

extension EnrollmentBaselineStoring {
    /// Supports existing stores by treating an ambiguous legacy nil as a read failure.
    public func loadChecked() async throws -> DomainState? {
        guard let state = await load() else {
            throw BiometricSessionError(code: .keychainFailure)
        }
        return state
    }
}
