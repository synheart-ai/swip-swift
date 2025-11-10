import Foundation

/// Manages SWIP sessions
public class SessionManager {
    private var sessions: [String: Session] = [:]
    private let queue = DispatchQueue(label: "ai.synheart.swip.sessionmanager")

    public init() {}

    /// Start a new session
    public func startSession(
        sessionId: String,
        appId: String,
        metadata: [String: Any]
    ) -> Session {
        let session = Session(
            id: sessionId,
            appId: appId,
            metadata: metadata,
            startTime: Date(),
            state: .active
        )

        queue.sync {
            sessions[sessionId] = session
        }

        return session
    }

    /// End a session
    public func endSession(sessionId: String) {
        queue.sync {
            if var session = sessions[sessionId] {
                session.state = .ended
                session.endTime = Date()
                sessions[sessionId] = session
            }
        }
    }

    /// Get a session by ID
    public func getSession(sessionId: String) -> Session? {
        return queue.sync {
            sessions[sessionId]
        }
    }

    /// Get all active sessions
    public func getActiveSessions() -> [Session] {
        return queue.sync {
            sessions.values.filter { $0.state == .active }
        }
    }

    /// Purge all data
    public func purgeAllData() {
        queue.sync {
            sessions.removeAll()
        }
    }
}

/// Session data structure
public struct Session {
    public let id: String
    public let appId: String
    public let metadata: [String: Any]
    public let startTime: Date
    public var endTime: Date?
    public var state: SessionState

    public init(
        id: String,
        appId: String,
        metadata: [String: Any],
        startTime: Date,
        endTime: Date? = nil,
        state: SessionState
    ) {
        self.id = id
        self.appId = appId
        self.metadata = metadata
        self.startTime = startTime
        self.endTime = endTime
        self.state = state
    }
}
