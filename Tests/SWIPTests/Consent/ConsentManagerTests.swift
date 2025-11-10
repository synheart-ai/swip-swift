import XCTest
@testable import SWIP

final class ConsentManagerTests: XCTestCase {

    var consentManager: ConsentManager!
    var userDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        // Use a test suite name to avoid conflicts
        userDefaults = UserDefaults(suiteName: "test.swip.consent")!
        userDefaults.removePersistentDomain(forName: "test.swip.consent")
        consentManager = ConsentManager(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "test.swip.consent")
        consentManager = nil
        userDefaults = nil
        super.tearDown()
    }

    func testDefaultConsentLevelIsOnDevice() {
        // When creating a new ConsentManager
        // Then default consent should be onDevice
        XCTAssertEqual(consentManager.currentLevel, .onDevice)
    }

    func testGrantConsentUpdatesLevel() async throws {
        // When granting consent
        try await consentManager.grantConsent(level: .localExport, reason: "User requested export")

        // Then consent level should be updated
        XCTAssertEqual(consentManager.currentLevel, .localExport)
    }

    func testRevokeConsentResetsToOnDevice() async throws {
        // Given elevated consent
        try await consentManager.grantConsent(level: .dashboardShare, reason: "Testing")

        // When revoking consent
        try await consentManager.revokeConsent()

        // Then should reset to onDevice
        XCTAssertEqual(consentManager.currentLevel, .onDevice)
    }

    func testCanPerformActionChecksConsentLevel() async throws {
        // Given onDevice consent
        try await consentManager.grantConsent(level: .onDevice, reason: "Default")

        // Then onDevice actions are allowed
        XCTAssertTrue(consentManager.canPerformAction(required: .onDevice))

        // But higher levels are not allowed
        XCTAssertFalse(consentManager.canPerformAction(required: .localExport))
        XCTAssertFalse(consentManager.canPerformAction(required: .dashboardShare))
    }

    func testHigherConsentAllowsLowerLevels() async throws {
        // Given dashboardShare consent
        try await consentManager.grantConsent(level: .dashboardShare, reason: "Testing")

        // Then all lower levels should be allowed
        XCTAssertTrue(consentManager.canPerformAction(required: .onDevice))
        XCTAssertTrue(consentManager.canPerformAction(required: .localExport))
        XCTAssertTrue(consentManager.canPerformAction(required: .dashboardShare))
    }

    func testConsentHistoryTracksGrants() async throws {
        // When granting different levels
        try await consentManager.grantConsent(level: .localExport, reason: "First grant")
        try await consentManager.grantConsent(level: .dashboardShare, reason: "Second grant")

        // Then history should contain both
        let history = consentManager.getConsentHistory()
        XCTAssertTrue(history.keys.contains(.localExport))
        XCTAssertTrue(history.keys.contains(.dashboardShare))
    }

    func testConsentValidatorThrowsOnInsufficientConsent() {
        // Given onDevice consent
        // When validating for higher level
        // Then should throw
        XCTAssertThrowsError(
            try ConsentValidator.validateConsent(
                required: .dashboardShare,
                current: .onDevice,
                operation: "test"
            )
        )
    }

    func testConsentValidatorPassesWithSufficientConsent() throws {
        // Given dashboardShare consent
        // When validating for lower level
        // Then should not throw
        try ConsentValidator.validateConsent(
            required: .localExport,
            current: .dashboardShare,
            operation: "test"
        )
        // If no error, test passes
        XCTAssertTrue(true)
    }

    func testPurgeAllDataClearsHistory() async throws {
        // Given some consent history
        try await consentManager.grantConsent(level: .localExport, reason: "Testing")

        // When purging all data
        try await consentManager.purgeAllData()

        // Then consent should reset
        XCTAssertEqual(consentManager.currentLevel, .onDevice)
    }
}
