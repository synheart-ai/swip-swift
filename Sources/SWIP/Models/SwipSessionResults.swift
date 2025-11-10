import Foundation

/// SWIP Session Results
public struct SwipSessionResults {
    public let sessionId: String
    public let scores: [SwipScoreResult]
    public let emotions: [EmotionResult]
    public let startTime: Date
    public let endTime: Date

    public init(
        sessionId: String,
        scores: [SwipScoreResult],
        emotions: [EmotionResult],
        startTime: Date,
        endTime: Date
    ) {
        self.sessionId = sessionId
        self.scores = scores
        self.emotions = emotions
        self.startTime = startTime
        self.endTime = endTime
    }

    /// Get summary statistics
    public func getSummary() -> [String: Any] {
        guard !scores.isEmpty else {
            return [
                "duration_seconds": 0,
                "average_swip_score": 0.0,
                "dominant_emotion": "Unknown"
            ]
        }

        let avgScore = scores.map { $0.swipScore }.reduce(0, +) / Double(scores.count)
        let dominantEmotion = getMostFrequentEmotion()

        return [
            "session_id": sessionId,
            "duration_seconds": endTime.timeIntervalSince(startTime),
            "average_swip_score": avgScore,
            "dominant_emotion": dominantEmotion,
            "score_count": scores.count,
            "emotion_count": emotions.count
        ]
    }

    /// Get most frequent emotion
    private func getMostFrequentEmotion() -> String {
        guard !scores.isEmpty else { return "Unknown" }

        var emotionCounts: [String: Int] = [:]
        for score in scores {
            emotionCounts[score.dominantEmotion, default: 0] += 1
        }

        return emotionCounts.max(by: { $0.value < $1.value })?.key ?? "Unknown"
    }
}

/// SWIP Score Result
public struct SwipScoreResult {
    public let swipScore: Double
    public let dominantEmotion: String
    public let emotionProbabilities: [String: Double]
    public let hrv: Double
    public let heartRate: Double
    public let timestamp: Date
    public let confidence: Double
    public let dataQuality: Double

    public init(
        swipScore: Double,
        dominantEmotion: String,
        emotionProbabilities: [String: Double],
        hrv: Double,
        heartRate: Double,
        timestamp: Date,
        confidence: Double = 0.0,
        dataQuality: Double = 1.0
    ) {
        self.swipScore = swipScore
        self.dominantEmotion = dominantEmotion
        self.emotionProbabilities = emotionProbabilities
        self.hrv = hrv
        self.heartRate = heartRate
        self.timestamp = timestamp
        self.confidence = confidence
        self.dataQuality = dataQuality
    }
}

/// Emotion Recognition Result
public struct EmotionResult {
    public let emotion: String
    public let confidence: Double
    public let probabilities: [String: Double]
    public let timestamp: Date

    public init(
        emotion: String,
        confidence: Double,
        probabilities: [String: Double],
        timestamp: Date
    ) {
        self.emotion = emotion
        self.confidence = confidence
        self.probabilities = probabilities
        self.timestamp = timestamp
    }
}
