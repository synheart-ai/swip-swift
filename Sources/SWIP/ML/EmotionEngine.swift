import Foundation

/// Emotion Recognition Engine
///
/// Processes HR/HRV data and predicts emotional states using on-device ML
public class EmotionEngine {
    private let config: EmotionConfig
    private let featureExtractor = FeatureExtractor()
    private let svmPredictor = SvmPredictor()

    private var dataBuffer: [DataPoint] = []
    private var results: [EmotionResult] = []

    private let queue = DispatchQueue(label: "ai.synheart.swip.emotionengine")

    private static let minBufferSize = 10
    private static let windowSize = 60
    private static let maxBufferSize = 300

    public init(config: EmotionConfig) {
        self.config = config
    }

    /// Push new physiological data
    public func push(hr: Double, hrv: Double, timestamp: Date, motion: Double) {
        queue.async { [weak self] in
            guard let self = self else { return }

            self.dataBuffer.append(
                DataPoint(
                    hr: hr,
                    hrv: hrv,
                    timestamp: timestamp,
                    motion: motion
                )
            )

            // Process if we have enough data
            if self.dataBuffer.count >= Self.minBufferSize {
                self.processBuffer()
            }
        }
    }

    /// Consume ready emotion results
    public func consumeReady() -> [EmotionResult] {
        return queue.sync {
            let ready = results
            results.removeAll()
            return ready
        }
    }

    /// Clear all data
    public func clear() {
        queue.sync {
            dataBuffer.removeAll()
            results.removeAll()
        }
    }

    private func processBuffer() {
        // Get latest window of data
        let window = Array(dataBuffer.suffix(Self.windowSize))

        // Extract features
        let features = featureExtractor.extract(from: window)

        // Predict emotion
        let prediction = svmPredictor.predict(features: features)

        // Create result
        let result = EmotionResult(
            emotion: prediction.emotion,
            confidence: prediction.confidence,
            probabilities: prediction.probabilities,
            timestamp: Date()
        )

        // Only add if confidence exceeds threshold
        if result.confidence >= config.confidenceThreshold {
            results.append(result)
        }

        // Remove old data to prevent memory growth
        while dataBuffer.count > Self.maxBufferSize {
            dataBuffer.removeFirst()
        }
    }
}

/// Data point for emotion recognition
public struct DataPoint {
    public let hr: Double
    public let hrv: Double
    public let timestamp: Date
    public let motion: Double

    public init(hr: Double, hrv: Double, timestamp: Date, motion: Double) {
        self.hr = hr
        self.hrv = hrv
        self.timestamp = timestamp
        self.motion = motion
    }
}

/// Emotion prediction result
public struct EmotionPrediction {
    public let emotion: String
    public let confidence: Double
    public let probabilities: [String: Double]

    public init(emotion: String, confidence: Double, probabilities: [String: Double]) {
        self.emotion = emotion
        self.confidence = confidence
        self.probabilities = probabilities
    }
}
