import Foundation
import Accelerate

/// Extracts HRV features from physiological data
public class FeatureExtractor {
    public init() {}

    /// Extract features from data window
    public func extract(from window: [DataPoint]) -> [Double] {
        guard !window.isEmpty else {
            return Array(repeating: 0.0, count: 6)
        }

        let hrs = window.map { $0.hr }
        let hrvs = window.map { $0.hrv }

        // Basic HR statistics
        let meanHR = hrs.reduce(0, +) / Double(hrs.count)
        let stdHR = calculateStdDev(values: hrs)
        let minHR = hrs.min() ?? 0.0
        let maxHR = hrs.max() ?? 0.0

        // HRV metrics
        let sdnn = hrvs.reduce(0, +) / Double(hrvs.count) // Simplified SDNN
        let rmssd = calculateRMSSD(values: hrvs)

        return [
            meanHR,
            stdHR,
            minHR,
            maxHR,
            sdnn,
            rmssd
        ]
    }

    private func calculateStdDev(values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }

        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }

    private func calculateRMSSD(values: [Double]) -> Double {
        guard values.count >= 2 else { return 0.0 }

        var squaredDiffs: [Double] = []
        for i in 0..<(values.count - 1) {
            let diff = values[i + 1] - values[i]
            squaredDiffs.append(diff * diff)
        }

        let meanSquaredDiff = squaredDiffs.reduce(0, +) / Double(squaredDiffs.count)
        return sqrt(meanSquaredDiff)
    }
}
