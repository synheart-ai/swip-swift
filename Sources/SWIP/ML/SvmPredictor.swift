import Foundation

/// Linear SVM Predictor for emotion recognition
///
/// Implements One-vs-Rest Linear SVM for 3 classes: Amused, Calm, Stressed
public class SvmPredictor {
    // Model weights and biases loaded from bundle
    private let weights: [String: [Double]]
    private let biases: [String: Double]
    private let featureMeans: [Double]
    private let featureStds: [Double]

    public init() {
        // Load actual model from bundle
        if let model = ModelLoader.loadSvmModel() {
            // Convert model to internal format
            var loadedWeights: [String: [Double]] = [:]
            var loadedBiases: [String: Double] = [:]

            for (index, className) in model.classes.enumerated() {
                loadedWeights[className] = model.weights[index]
                loadedBiases[className] = model.bias[index]
            }

            self.weights = loadedWeights
            self.biases = loadedBiases
            self.featureMeans = model.scalerMean
            self.featureStds = model.scalerScale
        } else {
            // Fallback to default values if model loading fails
            print("Warning: Using default SVM model weights")
            self.weights = [
                "Amused": [0.12, -0.33, 0.08, -0.19, 0.5, 0.3],
                "Calm": [-0.21, 0.55, -0.07, 0.1, -0.4, -0.3],
                "Stressed": [0.02, -0.12, 0.1, 0.05, 0.2, 0.1]
            ]

            self.biases = [
                "Amused": -0.2,
                "Calm": 0.3,
                "Stressed": 0.1
            ]

            self.featureMeans = [72.5, 8.2, 65.0, 85.0, 45.3, 32.1]
            self.featureStds = [12.0, 5.5, 8.0, 15.0, 18.7, 12.4]
        }
    }

    /// Predict emotion from features
    public func predict(features: [Double]) -> EmotionPrediction {
        // Normalize features
        let normalized = normalizeFeatures(features)

        // Compute scores for each class
        var scores: [String: Double] = [:]
        for (emotion, weight) in weights {
            let score = dotProduct(normalized, weight) + (biases[emotion] ?? 0.0)
            scores[emotion] = score
        }

        // Apply softmax to get probabilities
        let scoreValues = scores.values.map { $0 }
        let probabilities = softmax(scores: scoreValues)
        let probabilityMap = Dictionary(uniqueKeysWithValues: zip(scores.keys, probabilities))

        // Get dominant emotion
        let dominantEmotion = scores.max(by: { $0.value < $1.value })?.key ?? "Unknown"
        let confidence = probabilityMap[dominantEmotion] ?? 0.0

        return EmotionPrediction(
            emotion: dominantEmotion,
            confidence: confidence,
            probabilities: probabilityMap
        )
    }

    private func normalizeFeatures(_ features: [Double]) -> [Double] {
        return zip(features, zip(featureMeans, featureStds)).map { feature, stats in
            let (mean, std) = stats
            return (feature - mean) / std
        }
    }

    private func dotProduct(_ a: [Double], _ b: [Double]) -> Double {
        return zip(a, b).map(*).reduce(0, +)
    }

    private func softmax(scores: [Double]) -> [Double] {
        let maxScore = scores.max() ?? 0.0
        let expScores = scores.map { exp($0 - maxScore) }
        let sumExp = expScores.reduce(0, +)
        return expScores.map { $0 / sumExp }
    }
}
