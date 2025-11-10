import Foundation

/// Consent management for SWIP SDK
///
/// Implements privacy-first design with explicit consent gates
/// for all data sharing operations.
public class ConsentManager {
    private let userDefaults: UserDefaults
    private var _currentLevel: ConsentLevel
    private var grantHistory: [ConsentLevel: Date] = [:]
    private var grantReasons: [ConsentLevel: String] = [:]

    public var currentLevel: ConsentLevel {
        return _currentLevel
    }

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self._currentLevel = Self.loadCurrentLevel(from: userDefaults)
        loadConsentHistory()
    }

    /// Check if a specific action is allowed
    public func canPerformAction(required: ConsentLevel) -> Bool {
        return _currentLevel.allows(required)
    }

    /// Request consent for a specific level
    ///
    /// This should show UI to the user explaining what data will be shared.
    /// Returns true if user grants consent, false otherwise.
    public func requestConsent(
        requested: ConsentLevel,
        context: ConsentContext,
        customMessage: String? = nil
    ) async -> Bool {
        // If we already have sufficient consent, return true
        if _currentLevel.allows(requested) {
            return true
        }

        // Show consent dialog (this would be implemented by the app)
        let granted = await showConsentDialog(
            requested: requested,
            context: context,
            customMessage: customMessage
        )

        if granted {
            try? await grantConsent(level: requested, reason: context.reason)
        }

        return granted
    }

    /// Grant consent for a specific level
    public func grantConsent(level: ConsentLevel, reason: String) async throws {
        _currentLevel = level
        grantHistory[level] = Date()
        grantReasons[level] = reason

        // Persist consent
        try await persistConsent()
    }

    /// Revoke consent (downgrade to onDevice)
    public func revokeConsent() async throws {
        _currentLevel = .onDevice
        try await persistConsent()
    }

    /// Purge all user data (GDPR compliance)
    public func purgeAllData() async throws {
        // This would trigger deletion of all stored data
        try await purgeAllStoredData()

        // Reset consent
        _currentLevel = .onDevice
        grantHistory.removeAll()
        grantReasons.removeAll()
        try await persistConsent()
    }

    /// Get consent history for audit trail
    public func getConsentHistory() -> [ConsentLevel: ConsentRecord] {
        var history: [ConsentLevel: ConsentRecord] = [:]

        for level in [ConsentLevel.onDevice, .localExport, .dashboardShare] {
            if let grantedAt = grantHistory[level] {
                history[level] = ConsentRecord(
                    level: level,
                    grantedAt: grantedAt,
                    reason: grantReasons[level] ?? "Unknown"
                )
            }
        }

        return history
    }

    /// Check if consent is still valid (not expired)
    public func isConsentValid(level: ConsentLevel) -> Bool {
        guard let grantedAt = grantHistory[level] else { return false }

        // Consent expires after 1 year
        let expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: grantedAt)!
        return Date() < expirationDate
    }

    /// Get consent status for all levels
    public func getConsentStatus() -> [ConsentLevel: ConsentStatus] {
        var status: [ConsentLevel: ConsentStatus] = [:]

        for level in [ConsentLevel.onDevice, .localExport, .dashboardShare] {
            if level.rawValue <= _currentLevel.rawValue {
                status[level] = .granted
            } else {
                status[level] = .denied
            }
        }

        return status
    }

    // MARK: - Private Methods

    private func showConsentDialog(
        requested: ConsentLevel,
        context: ConsentContext,
        customMessage: String?
    ) async -> Bool {
        // This is a placeholder - the actual implementation would show
        // a proper consent dialog to the user
        let message = customMessage ?? getDefaultConsentMessage(requested: requested, context: context)

        // For now, return false (deny consent)
        // In a real implementation, this would show UI and return user's choice
        print("Consent requested: \(message)")
        return false
    }

    private func getDefaultConsentMessage(requested: ConsentLevel, context: ConsentContext) -> String {
        switch requested {
        case .onDevice:
            return "SWIP will process your data locally on your device. No data will be shared."
        case .localExport:
            return "You can export your SWIP data locally. No automatic sharing will occur."
        case .dashboardShare:
            return "Aggregated SWIP data may be shared with the SWIP Dashboard for research. Raw biosignals will never be transmitted."
        }
    }

    private func persistConsent() async throws {
        userDefaults.set(_currentLevel.rawValue, forKey: Keys.currentLevel)

        // Save grant history
        for (level, date) in grantHistory {
            userDefaults.set(date.timeIntervalSince1970, forKey: Keys.grantTime(level))
            userDefaults.set(grantReasons[level], forKey: Keys.grantReason(level))
        }

        userDefaults.synchronize()
        print("Consent persisted: \(_currentLevel)")
    }

    private static func loadCurrentLevel(from userDefaults: UserDefaults) -> ConsentLevel {
        let levelValue = userDefaults.integer(forKey: Keys.currentLevel)
        return ConsentLevel(rawValue: levelValue) ?? .onDevice
    }

    private func loadConsentHistory() {
        for level in [ConsentLevel.onDevice, .localExport, .dashboardShare] {
            let grantTime = userDefaults.double(forKey: Keys.grantTime(level))
            if grantTime > 0 {
                grantHistory[level] = Date(timeIntervalSince1970: grantTime)
                grantReasons[level] = userDefaults.string(forKey: Keys.grantReason(level)) ?? "Unknown"
            }
        }
    }

    private func purgeAllStoredData() async throws {
        // Clear all consent-related data
        for level in [ConsentLevel.onDevice, .localExport, .dashboardShare] {
            userDefaults.removeObject(forKey: Keys.grantTime(level))
            userDefaults.removeObject(forKey: Keys.grantReason(level))
        }
        userDefaults.removeObject(forKey: Keys.currentLevel)
        userDefaults.synchronize()

        print("All user data purged")
    }

    private struct Keys {
        static let currentLevel = "swip_consent_current_level"

        static func grantTime(_ level: ConsentLevel) -> String {
            return "swip_consent_grant_time_\(level.rawValue)"
        }

        static func grantReason(_ level: ConsentLevel) -> String {
            return "swip_consent_grant_reason_\(level.rawValue)"
        }
    }
}

/// Consent validation utilities
public struct ConsentValidator {
    /// Validate that required consent is present for an operation
    public static func validateConsent(
        required: ConsentLevel,
        current: ConsentLevel,
        operation: String? = nil
    ) throws {
        if !current.allows(required) {
            throw SwipError.consent(
                "Operation \"\(operation ?? "unknown")\" requires consent level \(required), " +
                "but current level is \(current)"
            )
        }
    }

    /// Check if consent is valid for a specific operation
    public static func isValidForOperation(
        required: ConsentLevel,
        current: ConsentLevel
    ) -> Bool {
        return current.allows(required)
    }
}
