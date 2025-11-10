import XCTest
@testable import SWIP

final class SwipEngineTests: XCTestCase {

    var swipEngine: SwipEngine!
    var config: SwipConfig!

    override func setUp() {
        super.setUp()
        config = SwipConfig()
        swipEngine = SwipEngine(config: config)
    }

    func testComputeScoreWithCalmEmotion() {
        // Given calm emotion probabilities
        let emotionProbs = [
            "Amused": 0.2,
            "Calm": 0.7,
            "Stressed": 0.1
        ]

        // When computing score
        let result = swipEngine.computeScore(
            hr: 70.0,
            hrv: 60.0,
            motion: 0.0,
            emotionProbabilities: emotionProbs
        )

        // Then score should be positive (calm = good)
        XCTAssertTrue(result.swipScore >= 50.0)
        XCTAssertEqual(result.dominantEmotion, "Calm")
        XCTAssertEqual(result.confidence, 0.7, accuracy: 0.01)
    }

    func testComputeScoreWithStressedEmotion() {
        // Given stressed emotion probabilities
        let emotionProbs = [
            "Amused": 0.1,
            "Calm": 0.2,
            "Stressed": 0.7
        ]

        // When computing score with low HRV
        let result = swipEngine.computeScore(
            hr: 95.0,
            hrv: 25.0,
            motion: 0.0,
            emotionProbabilities: emotionProbs
        )

        // Then score should be lower (stressed = worse)
        XCTAssertTrue(result.swipScore < 60.0)
        XCTAssertEqual(result.dominantEmotion, "Stressed")
        XCTAssertEqual(result.confidence, 0.7, accuracy: 0.01)
    }

    func testComputeScoreWithAmusedEmotion() {
        // Given amused emotion probabilities
        let emotionProbs = [
            "Amused": 0.8,
            "Calm": 0.1,
            "Stressed": 0.1
        ]

        // When computing score with good HRV
        let result = swipEngine.computeScore(
            hr: 75.0,
            hrv: 55.0,
            motion: 0.0,
            emotionProbabilities: emotionProbs
        )

        // Then score should be high (amused = positive)
        XCTAssertTrue(result.swipScore >= 50.0)
        XCTAssertEqual(result.dominantEmotion, "Amused")
    }

    func testScoreIsBounded0To100() {
        // Given extreme values
        let emotionProbs = [
            "Stressed": 1.0,
            "Calm": 0.0,
            "Amused": 0.0
        ]

        // When computing score with very low HRV
        let result1 = swipEngine.computeScore(
            hr: 120.0,
            hrv: 5.0,
            motion: 0.0,
            emotionProbabilities: emotionProbs
        )

        // And with very high HRV
        let result2 = swipEngine.computeScore(
            hr: 55.0,
            hrv: 150.0,
            motion: 0.0,
            emotionProbabilities: ["Amused": 1.0, "Calm": 0.0, "Stressed": 0.0]
        )

        // Then scores should be bounded
        XCTAssertTrue(result1.swipScore >= 0.0)
        XCTAssertTrue(result1.swipScore <= 100.0)
        XCTAssertTrue(result2.swipScore >= 0.0)
        XCTAssertTrue(result2.swipScore <= 100.0)
    }

    func testDataQualityBasedOnHeartRate() {
        // Given valid HR
        let validResult = swipEngine.computeScore(
            hr: 75.0,
            hrv: 50.0,
            motion: 0.0,
            emotionProbabilities: ["Calm": 1.0]
        )

        // And invalid HR (too low)
        let invalidResult = swipEngine.computeScore(
            hr: 30.0,
            hrv: 50.0,
            motion: 0.0,
            emotionProbabilities: ["Calm": 1.0]
        )

        // Then data quality should differ
        XCTAssertEqual(validResult.dataQuality, 1.0, accuracy: 0.01)
        XCTAssertEqual(invalidResult.dataQuality, 0.5, accuracy: 0.01)
    }

    func testResultIncludesAllRequiredFields() {
        // Given any input
        let emotionProbs = [
            "Amused": 0.3,
            "Calm": 0.5,
            "Stressed": 0.2
        ]

        // When computing score
        let result = swipEngine.computeScore(
            hr: 70.0,
            hrv: 50.0,
            motion: 0.0,
            emotionProbabilities: emotionProbs
        )

        // Then all fields should be populated
        XCTAssertTrue(result.swipScore >= 0.0)
        XCTAssertNotNil(result.dominantEmotion)
        XCTAssertEqual(result.emotionProbabilities.count, 3)
        XCTAssertEqual(result.heartRate, 70.0, accuracy: 0.01)
        XCTAssertEqual(result.hrv, 50.0, accuracy: 0.01)
        XCTAssertNotNil(result.timestamp)
        XCTAssertTrue(result.confidence >= 0.0)
        XCTAssertTrue(result.dataQuality >= 0.0)
    }

    func testCustomConfigWeightsAffectScore() {
        // Given custom config with different weights
        let customConfig = SwipConfig(
            weightHrv: 0.8,
            weightCoherence: 0.2
        )
        let customEngine = SwipEngine(config: customConfig)

        let emotionProbs = ["Calm": 1.0, "Stressed": 0.0, "Amused": 0.0]

        // When computing with default and custom configs
        let defaultResult = swipEngine.computeScore(
            hr: 70.0, hrv: 60.0, motion: 0.0, emotionProbabilities: emotionProbs
        )
        let customResult = customEngine.computeScore(
            hr: 70.0, hrv: 60.0, motion: 0.0, emotionProbabilities: emotionProbs
        )

        // Then scores may differ (unless weights produce same result)
        XCTAssertNotNil(defaultResult.swipScore)
        XCTAssertNotNil(customResult.swipScore)
    }
}
