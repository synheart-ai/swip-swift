import Foundation
import Combine
import SynheartWear
import SwipCore

/// SWIP SDK Manager - Main entry point for the iOS SDK
///
/// Integrates:
/// - SynheartWear: Reads HR, HRV data from HealthKit via biosignal collection layer
/// - EmotionEngine: Runs emotion inference models
/// - SwipEngine: Computes SWIP Score from SwipCore
public class SwipSdkManager {
    // Core components
    private let synheartWear: SynheartWear
    private let emotionEngine: EmotionEngine
    private let baseline: PhysiologicalBaseline
    private let swipEngine: SwipEngine
    private let consentManager: ConsentManager
    private let sessionManager: SessionManager

    // State
    private var initialized = false
    private var activeSessionId: String?

    // Publishers
    private let scoreSubject = PassthroughSubject<SwipScoreResult, Never>()
    public var scorePublisher: AnyPublisher<SwipScoreResult, Never> {
        scoreSubject.eraseToAnyPublisher()
    }

    private let emotionSubject = PassthroughSubject<EmotionResult, Never>()
    public var emotionPublisher: AnyPublisher<EmotionResult, Never> {
        emotionSubject.eraseToAnyPublisher()
    }

    // Session data
    private var sessionScores: [SwipScoreResult] = []
    private var sessionEmotions: [EmotionResult] = []

    // Processing
    private var processingTimer: Timer?

    // Configuration
    private let config: SwipSdkConfig

    /// Initialize SWIP SDK
    ///
    /// - Parameter config: SDK configuration
    public init(config: SwipSdkConfig = SwipSdkConfig()) {
        self.config = config
        self.synheartWear = SynheartWear(
            config: SynheartWearConfig(
                enabledAdapters: [.appleHealthKit],
                enableLocalCaching: false,
                enableEncryption: true,
                streamInterval: 1000 // 1 second
            )
        )
        self.emotionEngine = EmotionEngine(config: config.emotionConfig)
        self.baseline = PhysiologicalBaseline(
            restingHr: 70.0,
            restingHrv: 50.0
        )
        self.swipEngine = SwipEngine(
            baseline: baseline,
            config: .default
        )
        self.consentManager = ConsentManager()
        self.sessionManager = SessionManager()
    }

    /// Initialize the SDK
    public func initialize() async throws {
        if initialized { return }

        do {
            // Initialize SynheartWear SDK
            try await synheartWear.initialize()

            initialized = true
            log(level: "info", message: "SWIP SDK initialized")
        } catch {
            log(level: "error", message: "Failed to initialize: \(error)")
            throw SwipError.initialization("Failed to initialize SWIP SDK: \(error)")
        }
    }

    /// Request health permissions
    public func requestPermissions() async throws {
        guard initialized else {
            throw SwipError.invalidConfiguration("SWIP SDK not initialized")
        }

        do {
            let permissions: Set<PermissionType> = [
                .heartRate,
                .heartRateVariability
            ]

            _ = try await synheartWear.requestPermissions(permissions)
        } catch {
            log(level: "error", message: "Failed to request permissions: \(error)")
            throw SwipError.initialization("Failed to request permissions: \(error)")
        }
    }

    /// Start a session for an app
    ///
    /// - Parameters:
    ///   - appId: Application identifier
    ///   - metadata: Optional session metadata
    /// - Returns: Session ID
    public func startSession(appId: String, metadata: [String: Any] = [:]) async throws -> String {
        guard initialized else {
            throw SwipError.invalidConfiguration("SWIP SDK not initialized")
        }

        guard activeSessionId == nil else {
            throw SwipError.session("Session already in progress")
        }

        // Generate session ID
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        activeSessionId = "\(timestamp)_\(appId)"

        // Clear previous session data
        sessionScores.removeAll()
        sessionEmotions.removeAll()

        // Start session in session manager
        sessionManager.startSession(sessionId: activeSessionId!, appId: appId, metadata: metadata)

        // Start data processing
        startDataProcessing()

        log(level: "info", message: "Session started: \(activeSessionId!)")
        return activeSessionId!
    }

    /// Stop the current session
    ///
    /// - Returns: Session results
    public func stopSession() async throws -> SwipSessionResults {
        guard let sessionId = activeSessionId else {
            throw SwipError.session("No active session")
        }

        // Stop data processing
        stopDataProcessing()

        // Get session
        guard let session = sessionManager.getSession(sessionId: sessionId) else {
            throw SwipError.session("Session not found")
        }

        // Create session results
        let results = SwipSessionResults(
            sessionId: sessionId,
            scores: sessionScores,
            emotions: sessionEmotions,
            startTime: session.startTime,
            endTime: Date()
        )

        // End session in session manager
        sessionManager.endSession(sessionId: sessionId)

        // Clear session data
        sessionScores.removeAll()
        sessionEmotions.removeAll()
        activeSessionId = nil

        log(level: "info", message: "Session stopped: \(sessionId)")
        return results
    }

    /// Get current SWIP score
    public func getCurrentScore() -> SwipScoreResult? {
        return sessionScores.last
    }

    /// Get current emotion
    public func getCurrentEmotion() -> EmotionResult? {
        return sessionEmotions.last
    }

    /// Set user consent level
    public func setUserConsent(level: ConsentLevel, reason: String) async throws {
        try await consentManager.grantConsent(level: level, reason: reason)
    }

    /// Get current consent level
    public func getUserConsent() -> ConsentLevel {
        return consentManager.currentLevel
    }

    /// Purge all user data (GDPR compliance)
    public func purgeAllData() async throws {
        // Stop any active session
        if activeSessionId != nil {
            do {
                _ = try await stopSession()
            } catch {
                log(level: "warn", message: "Failed to stop session during purge: \(error)")
            }
        }

        // Clear all data
        sessionScores.removeAll()
        sessionEmotions.removeAll()
        sessionManager.purgeAllData()
        try await consentManager.purgeAllData()

        log(level: "info", message: "All user data purged")
    }

    // MARK: - Private Methods

    private func startDataProcessing() {
        processingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task {
                await self?.processHealthData()
            }
        }
    }

    private func stopDataProcessing() {
        processingTimer?.invalidate()
        processingTimer = nil
    }

    private func processHealthData() async {
        do {
            // Read biometric data from SynheartWear
            let metrics = try await synheartWear.readMetrics(isRealTime: true)

            guard let hr = metrics.get("hr"),
                  let hrv = metrics.get("hrv_sdnn") else {
                return
            }

            let motion = metrics.get("motion") ?? 0.0
            let now = Date()

            // Push to emotion engine
            emotionEngine.push(hr: hr, hrv: hrv, timestamp: now, motion: motion)

            // Get emotion result if ready
            let emotionResults = emotionEngine.consumeReady()
            if let latestEmotion = emotionResults.last {
                sessionEmotions.append(latestEmotion)
                emotionSubject.send(latestEmotion)

                // Convert EmotionResult to EmotionSnapshot
                let arousalScore: Double
                switch latestEmotion.emotion.lowercased() {
                case "stressed":
                    arousalScore = 0.8
                case "amused", "excited":
                    arousalScore = 0.6
                case "calm", "relaxed":
                    arousalScore = 0.2
                default:
                    arousalScore = 0.5
                }

                let emotionSnapshot = EmotionSnapshot(
                    arousalScore: arousalScore,
                    state: latestEmotion.emotion,
                    confidence: latestEmotion.confidence,
                    warmingUp: false
                )

                // Compute SWIP score
                let swipResult = swipEngine.computeScore(
                    hr: hr,
                    hrv: hrv,
                    motion: motion,
                    emotion: emotionSnapshot
                )

                sessionScores.append(swipResult)
                scoreSubject.send(swipResult)

                log(level: "debug", message: "SWIP Score: \(String(format: "%.1f", swipResult.swipScore))")
            }
        } catch {
            log(level: "warn", message: "Failed to process health data: \(error)")
        }
    }

    private func log(level: String, message: String) {
        if config.enableLogging {
            print("[SWIP SDK] [\(level)] \(message)")
        }
    }
}
