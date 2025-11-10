import XCTest
@testable import SWIP

final class FeatureExtractorTests: XCTestCase {

    var featureExtractor: FeatureExtractor!

    override func setUp() {
        super.setUp()
        featureExtractor = FeatureExtractor()
    }

    func testExtractFeaturesFromEmptyWindow() {
        // Given an empty data window
        let emptyWindow: [DataPoint] = []

        // When extracting features
        let features = featureExtractor.extract(from: emptyWindow)

        // Then should return zero-filled array
        XCTAssertEqual(features.count, 6)
        XCTAssertTrue(features.allSatisfy { $0 == 0.0 })
    }

    func testExtractFeaturesFromSingleDataPoint() {
        // Given a single data point
        let window = [
            DataPoint(hr: 75.0, hrv: 50.0, timestamp: Date(), motion: 0.0)
        ]

        // When extracting features
        let features = featureExtractor.extract(from: window)

        // Then should return valid features
        XCTAssertEqual(features.count, 6)
        XCTAssertEqual(features[0], 75.0, accuracy: 0.01) // Mean HR
        XCTAssertEqual(features[1], 0.0, accuracy: 0.01)  // Std HR (single point = 0)
        XCTAssertEqual(features[2], 75.0, accuracy: 0.01) // Min HR
        XCTAssertEqual(features[3], 75.0, accuracy: 0.01) // Max HR
    }

    func testExtractFeaturesFromNormalWindow() {
        // Given a window of data points with varying HR/HRV
        let window = [
            DataPoint(hr: 70.0, hrv: 45.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 75.0, hrv: 50.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 80.0, hrv: 55.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 85.0, hrv: 60.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 90.0, hrv: 65.0, timestamp: Date(), motion: 0.0)
        ]

        // When extracting features
        let features = featureExtractor.extract(from: window)

        // Then should return correct statistics
        XCTAssertEqual(features.count, 6)
        XCTAssertEqual(features[0], 80.0, accuracy: 0.01)  // Mean HR
        XCTAssertTrue(features[1] > 0)                     // Std HR > 0
        XCTAssertEqual(features[2], 70.0, accuracy: 0.01)  // Min HR
        XCTAssertEqual(features[3], 90.0, accuracy: 0.01)  // Max HR
        XCTAssertEqual(features[4], 55.0, accuracy: 0.01)  // SDNN (mean HRV)
        XCTAssertTrue(features[5] > 0)                     // RMSSD > 0
    }

    func testFeatureArraySizeIsConsistent() {
        // Given windows of different sizes
        let smallWindow = [
            DataPoint(hr: 75.0, hrv: 50.0, timestamp: Date(), motion: 0.0)
        ]
        let largeWindow = (1...100).map { i in
            DataPoint(hr: 70.0 + Double(i), hrv: 40.0 + Double(i), timestamp: Date(), motion: 0.0)
        }

        // When extracting features
        let smallFeatures = featureExtractor.extract(from: smallWindow)
        let largeFeatures = featureExtractor.extract(from: largeWindow)

        // Then feature array size should be consistent
        XCTAssertEqual(smallFeatures.count, 6)
        XCTAssertEqual(largeFeatures.count, 6)
    }

    func testRMSSDCalculationWithConsecutiveValues() {
        // Given data points with known differences
        let window = [
            DataPoint(hr: 75.0, hrv: 40.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 75.0, hrv: 50.0, timestamp: Date(), motion: 0.0),
            DataPoint(hr: 75.0, hrv: 60.0, timestamp: Date(), motion: 0.0)
        ]

        // When extracting features
        let features = featureExtractor.extract(from: window)

        // Then RMSSD should be non-zero
        XCTAssertTrue(features[5] > 0) // RMSSD index
    }
}
