import Foundation

/// Base SWIP error
public enum SwipError: Error, CustomStringConvertible {
    case initialization(String)
    case invalidConfiguration(String)
    case sessionNotFound(String)
    case dataQuality(String)
    case session(String)
    case sensor(String)
    case model(String)
    case consent(String)
    case storage(String)
    case permission(String)

    public var description: String {
        switch self {
        case .initialization(let msg):
            return "Initialization Error: \(msg)"
        case .invalidConfiguration(let msg):
            return "Invalid Configuration: \(msg)"
        case .sessionNotFound(let msg):
            return "Session Not Found: \(msg)"
        case .dataQuality(let msg):
            return "Data Quality Error: \(msg)"
        case .session(let msg):
            return "Session Error: \(msg)"
        case .sensor(let msg):
            return "Sensor Error: \(msg)"
        case .model(let msg):
            return "Model Error: \(msg)"
        case .consent(let msg):
            return "Consent Error: \(msg)"
        case .storage(let msg):
            return "Storage Error: \(msg)"
        case .permission(let msg):
            return "Permission Error: \(msg)"
        }
    }

    public var code: String {
        switch self {
        case .initialization: return "E_INITIALIZATION_FAILED"
        case .invalidConfiguration: return "E_INVALID_CONFIG"
        case .sessionNotFound: return "E_SESSION_NOT_FOUND"
        case .dataQuality: return "E_SIGNAL_LOW_QUALITY"
        case .session: return "E_SESSION_ERROR"
        case .sensor: return "E_SENSOR_ERROR"
        case .model: return "E_MODEL_ERROR"
        case .consent: return "E_CONSENT_REQUIRED"
        case .storage: return "E_STORAGE_ERROR"
        case .permission: return "E_PERMISSION_DENIED"
        }
    }
}
