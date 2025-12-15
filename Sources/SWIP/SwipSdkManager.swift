import Foundation
import Combine
import HealthKit

/// SWIP SDK Manager - Main entry point for the iOS SDK
///
/// Integrates:
/// - HealthKit: Reads HR, HRV data
/// - EmotionEngine: Runs emotion inference models
/// - SwipEngine: Computes SWIP Score
public class SwipSdkManager {
    // Core components
    private let healthStore: HKHealthStore
    private let emotionEngine: EmotionEngine
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
        self.healthStore = HKHealthStore()
        self.emotionEngine = EmotionEngine(config: config.emotionConfig)
        self.swipEngine = SwipEngine(config: config.swipConfig)
        self.consentManager = ConsentManager()
        self.sessionManager = SessionManager()
    }

    /// Initialize the SDK
    public func initialize() async throws {
        if initialized { return }

        guard HKHealthStore.isHealthDataAvailable() else {
            throw SwipError.initialization("HealthKit not available")
        }

        initialized = true
        log(level: "info", message: "SWIP SDK initialized")
    }

    /// Request health permissions
    public func requestPermissions() async throws {
        guard initialized else {
            throw SwipError.invalidConfiguration("SWIP SDK not initialized")
        }

        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        ]

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
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
            // Read heart rate data from HealthKit
            let now = Date()
            let fiveSecondsAgo = now.addingTimeInterval(-5)

            let hr = try await readLatestHeartRate(startTime: fiveSecondsAgo, endTime: now)
            let hrv = try await readLatestHRV(startTime: fiveSecondsAgo, endTime: now)

            guard let heartRate = hr, let hrvValue = hrv else { return }

            // Push to emotion engine
            emotionEngine.push(hr: heartRate, hrv: hrvValue, timestamp: now, motion: 0.0)

            // Get emotion result if ready
            let emotionResults = emotionEngine.consumeReady()
            if let latestEmotion = emotionResults.last {
                sessionEmotions.append(latestEmotion)
                emotionSubject.send(latestEmotion)

                // Compute SWIP score
                let swipResult = swipEngine.computeScore(
                    hr: heartRate,
                    hrv: hrvValue,
                    motion: 0.0,
                    emotionProbabilities: latestEmotion.probabilities
                )

                sessionScores.append(swipResult)
                scoreSubject.send(swipResult)

                log(level: "debug", message: "SWIP Score: \(String(format: "%.1f", swipResult.swipScore))")
            }
        } catch {
            log(level: "warn", message: "Failed to process health data: \(error)")
        }
    }

    private func readLatestHeartRate(startTime: Date, endTime: Date) async throws -> Double? {
        let quantityType = try requireQuantityType(.heartRate)
        let unit = HKUnit.count().unitDivided(by: .minute())
        return try await queryLatestQuantitySample(
            of: quantityType,
            startTime: startTime,
            endTime: endTime,
            unit: unit
        )
    }

    private func readLatestHRV(startTime: Date, endTime: Date) async throws -> Double? {
        // HealthKit stores SDNN in seconds; this SDK uses milliseconds (ms).
        let quantityType = try requireQuantityType(.heartRateVariabilitySDNN)
        let unit = HKUnit.secondUnit(with: .milli)
        return try await queryLatestQuantitySample(
            of: quantityType,
            startTime: startTime,
            endTime: endTime,
            unit: unit
        )
    }

    private func requireQuantityType(_ identifier: HKQuantityTypeIdentifier) throws -> HKQuantityType {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else {
            throw SwipError.initialization("HealthKit quantity type not available: \(identifier.rawValue)")
        }
        return type
    }

    private func queryLatestQuantitySample(
        of quantityType: HKQuantityType,
        startTime: Date,
        endTime: Date,
        unit: HKUnit
    ) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard
                    let sample = (samples as? [HKQuantitySample])?.first
                else {
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: sample.quantity.doubleValue(for: unit))
            }

            self.healthStore.execute(query)
        }
    }
    
    private func log(level: String, message: String) {
        if config.enableLogging {
            print("[SWIP SDK] [\(level)] \(message)")
        }
    }
}
