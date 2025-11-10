import Foundation

/// Data types and enums for SWIP SDK

/// Consent levels for data sharing
public enum ConsentLevel: Int {
    /// Level 0: On-device only (default)
    case onDevice = 0

    /// Level 1: Local export allowed
    case localExport = 1

    /// Level 2: Dashboard sharing allowed
    case dashboardShare = 2

    /// Check if this level allows the requested action
    public func allows(_ required: ConsentLevel) -> Bool {
        return self.rawValue >= required.rawValue
    }

    /// Get human-readable description
    public var description: String {
        switch self {
        case .onDevice:
            return "On-device only - no data sharing"
        case .localExport:
            return "Local export - manual data export allowed"
        case .dashboardShare:
            return "Dashboard sharing - aggregated data can be uploaded"
        }
    }
}

/// SWIP Score interpretation ranges
public enum SwipScoreRange {
    case positive
    case neutral
    case mildStress
    case negative

    public var range: ClosedRange<Int> {
        switch self {
        case .positive: return 80...100
        case .neutral: return 60...79
        case .mildStress: return 40...59
        case .negative: return 0...39
        }
    }

    /// Check if score falls in this range
    public func contains(_ score: Double) -> Bool {
        let intScore = Int(score)
        return range.contains(intScore)
    }

    /// Get human-readable description
    public var description: String {
        switch self {
        case .positive:
            return "Relaxed/Engaged - app supports wellness"
        case .neutral:
            return "Emotionally stable"
        case .mildStress:
            return "Cognitive or emotional fatigue"
        case .negative:
            return "Stress/emotional load detected"
        }
    }

    public static func forScore(_ score: Double) -> SwipScoreRange {
        if SwipScoreRange.positive.contains(score) { return .positive }
        if SwipScoreRange.neutral.contains(score) { return .neutral }
        if SwipScoreRange.mildStress.contains(score) { return .mildStress }
        return .negative
    }
}

/// Emotion classes supported by the system
public enum EmotionClass: String {
    case amused = "Amused"
    case calm = "Calm"
    case focused = "Focused"
    case neutral = "Neutral"
    case stressed = "Stressed"

    public var utility: Double {
        switch self {
        case .amused: return 0.95
        case .calm: return 0.85
        case .focused: return 0.80
        case .neutral: return 0.70
        case .stressed: return 0.15
        }
    }
}

/// Session states
public enum SessionState {
    case idle
    case starting
    case active
    case stopping
    case ended
    case error

    public var isActive: Bool { self == .active }
    public var canStart: Bool { self == .idle || self == .ended }
    public var canStop: Bool { self == .active || self == .starting }
}

/// Data quality levels
public enum DataQuality {
    case high
    case medium
    case low

    public var range: ClosedRange<Double> {
        switch self {
        case .high: return 0.7...1.0
        case .medium: return 0.4...(0.7.nextDown)
        case .low: return 0.0...(0.4.nextDown)
        }
    }

    public var isAcceptable: Bool { self != .low }

    public static func forScore(_ score: Double) -> DataQuality {
        if DataQuality.high.range.contains(score) { return .high }
        if DataQuality.medium.range.contains(score) { return .medium }
        return .low
    }
}

/// Consent status
public enum ConsentStatus {
    case granted
    case denied
    case expired
}

/// Consent context for requests
public struct ConsentContext {
    public let appId: String
    public let reason: String
    public let metadata: [String: Any]?

    public init(appId: String, reason: String, metadata: [String: Any]? = nil) {
        self.appId = appId
        self.reason = reason
        self.metadata = metadata
    }
}

/// Consent record for audit trail
public struct ConsentRecord {
    public let level: ConsentLevel
    public let grantedAt: Date
    public let reason: String

    public init(level: ConsentLevel, grantedAt: Date, reason: String) {
        self.level = level
        self.grantedAt = grantedAt
        self.reason = reason
    }

    public func toJSON() -> [String: Any] {
        return [
            "level": level.rawValue,
            "level_name": "\(level)",
            "granted_at": ISO8601DateFormatter().string(from: grantedAt),
            "reason": reason
        ]
    }

    public static func fromJSON(_ json: [String: Any]) -> ConsentRecord? {
        guard let levelValue = json["level"] as? Int,
              let level = ConsentLevel(rawValue: levelValue),
              let grantedAtString = json["granted_at"] as? String,
              let grantedAt = ISO8601DateFormatter().date(from: grantedAtString),
              let reason = json["reason"] as? String else {
            return nil
        }

        return ConsentRecord(level: level, grantedAt: grantedAt, reason: reason)
    }
}
