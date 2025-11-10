import Foundation

/// SWIP Score computation engine
///
/// Computes wellness impact scores based on HRV, emotion, and physiological data
public class SwipEngine {
    private let config: SwipConfig

    public init(config: SwipConfig) {
        self.config = config
    }

    /// Compute SWIP score
    ///
    /// - Parameters:
    ///   - hr: Heart rate (BPM)
    ///   - hrv: Heart rate variability (SDNN in ms)
    ///   - motion: Motion magnitude
    ///   - emotionProbabilities: Emotion prediction probabilities
    /// - Returns: SWIP score result
    public func computeScore(
        hr: Double,
        hrv: Double,
        motion: Double,
        emotionProbabilities: [String: Double]
    ) -> SwipScoreResult {
        // Get dominant emotion
        let dominantEmotion = emotionProbabilities.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        let emotionConfidence = emotionProbabilities[dominantEmotion] ?? 0.0

        // Compute baseline HRV score (normalized to 0-100)
        let hrvScore = normalizeHRV(hrv)

        // Compute coherence score based on emotion
        let coherenceScore = computeCoherence(emotionProbabilities: emotionProbabilities)

        // Weighted combination
        let swipScore = min(max(
            config.weightHrv * hrvScore +
            config.weightCoherence * coherenceScore,
            0.0
        ), 100.0)

        // Compute data quality (simplified - based on HR validity)
        let dataQuality = (40.0...200.0).contains(hr) ? 1.0 : 0.5

        return SwipScoreResult(
            swipScore: swipScore,
            dominantEmotion: dominantEmotion,
            emotionProbabilities: emotionProbabilities,
            hrv: hrv,
            heartRate: hr,
            timestamp: Date(),
            confidence: emotionConfidence,
            dataQuality: dataQuality
        )
    }

    /// Normalize HRV to 0-100 scale
    private func normalizeHRV(_ hrv: Double) -> Double {
        // Typical SDNN range is 20-100ms
        // Higher HRV = better (more relaxed)
        let normalized = ((hrv - 20.0) / 80.0) * 100.0
        return min(max(normalized, 0.0), 100.0)
    }

    /// Compute coherence score from emotion probabilities
    private func computeCoherence(emotionProbabilities: [String: Double]) -> Double {
        // Positive emotions (Amused, Calm) increase coherence
        // Negative emotions (Stressed) decrease coherence
        let positiveWeight = (emotionProbabilities["Amused"] ?? 0.0) * 1.0 +
                             (emotionProbabilities["Calm"] ?? 0.0) * 0.9
        let negativeWeight = (emotionProbabilities["Stressed"] ?? 0.0) * 0.2

        let coherence = (positiveWeight - negativeWeight) * 100.0
        return min(max(coherence, 0.0), 100.0)
    }
}
