import XCTest
@testable import SWIP

final class SessionManagerTests: XCTestCase {

    var sessionManager: SessionManager!

    override func setUp() {
        super.setUp()
        sessionManager = SessionManager()
    }

    override func tearDown() {
        sessionManager = nil
        super.tearDown()
    }

    func testStartSessionCreatesNewSession() {
        // When starting a session
        let session = sessionManager.startSession(
            sessionId: "test-123",
            appId: "com.example.app",
            metadata: ["screen": "home"]
        )

        // Then session should be created
        XCTAssertEqual(session.id, "test-123")
        XCTAssertEqual(session.appId, "com.example.app")
        XCTAssertEqual(session.state, .active)
    }

    func testGetSessionReturnsExistingSession() {
        // Given a started session
        sessionManager.startSession(
            sessionId: "test-123",
            appId: "com.example.app",
            metadata: [:]
        )

        // When retrieving the session
        let session = sessionManager.getSession(sessionId: "test-123")

        // Then session should be returned
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.id, "test-123")
    }

    func testGetSessionReturnsNilForNonExistentSession() {
        // When retrieving a non-existent session
        let session = sessionManager.getSession(sessionId: "non-existent")

        // Then should return nil
        XCTAssertNil(session)
    }

    func testEndSessionUpdatesState() {
        // Given an active session
        sessionManager.startSession(
            sessionId: "test-123",
            appId: "com.example.app",
            metadata: [:]
        )

        // When ending the session
        sessionManager.endSession(sessionId: "test-123")

        // Then session state should be ended
        let session = sessionManager.getSession(sessionId: "test-123")
        XCTAssertEqual(session?.state, .ended)
        XCTAssertNotNil(session?.endTime)
    }

    func testGetActiveSessionsReturnsOnlyActiveSessions() {
        // Given multiple sessions
        sessionManager.startSession(sessionId: "session-1", appId: "app1", metadata: [:])
        sessionManager.startSession(sessionId: "session-2", appId: "app2", metadata: [:])
        sessionManager.endSession(sessionId: "session-1")

        // When getting active sessions
        let activeSessions = sessionManager.getActiveSessions()

        // Then only active session should be returned
        XCTAssertEqual(activeSessions.count, 1)
        XCTAssertEqual(activeSessions[0].id, "session-2")
    }

    func testPurgeAllDataClearsSessions() {
        // Given multiple sessions
        sessionManager.startSession(sessionId: "session-1", appId: "app1", metadata: [:])
        sessionManager.startSession(sessionId: "session-2", appId: "app2", metadata: [:])

        // When purging all data
        sessionManager.purgeAllData()

        // Then all sessions should be cleared
        XCTAssertNil(sessionManager.getSession(sessionId: "session-1"))
        XCTAssertNil(sessionManager.getSession(sessionId: "session-2"))
        XCTAssertTrue(sessionManager.getActiveSessions().isEmpty)
    }

    func testSessionMetadataIsPreserved() {
        // Given a session with metadata
        let metadata: [String: Any] = [
            "screen": "meditation",
            "duration_minutes": 10,
            "user_id": "user-123"
        ]

        sessionManager.startSession(
            sessionId: "test-123",
            appId: "com.example.app",
            metadata: metadata
        )

        // When retrieving the session
        let session = sessionManager.getSession(sessionId: "test-123")

        // Then metadata should be preserved
        XCTAssertEqual(session?.metadata["screen"] as? String, "meditation")
        XCTAssertEqual(session?.metadata["duration_minutes"] as? Int, 10)
        XCTAssertEqual(session?.metadata["user_id"] as? String, "user-123")
    }

    func testConcurrentSessionsAreSupported() {
        // When starting multiple sessions
        sessionManager.startSession(sessionId: "session-1", appId: "app1", metadata: [:])
        sessionManager.startSession(sessionId: "session-2", appId: "app2", metadata: [:])
        sessionManager.startSession(sessionId: "session-3", appId: "app3", metadata: [:])

        // Then all should be active
        let activeSessions = sessionManager.getActiveSessions()
        XCTAssertEqual(activeSessions.count, 3)
    }
}
