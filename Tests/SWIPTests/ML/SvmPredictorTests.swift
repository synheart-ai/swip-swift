import XCTest
@testable import SWIP

final class SvmPredictorTests: XCTestCase {

    var svmPredictor: SvmPredictor!

    override func setUp() {
        super.setUp()
        svmPredictor = SvmPredictor()
    }

    func testPredictWithZeroFeatures() {
        // Given zero features
        let features = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then should return valid prediction
        XCTAssertNotNil(prediction.emotion)
        XCTAssertTrue(prediction.confidence >= 0.0 && prediction.confidence <= 1.0)
        XCTAssertEqual(prediction.probabilities.count, 3) // 3 emotion classes

        // Probabilities should sum to ~1.0
        let probSum = prediction.probabilities.values.reduce(0, +)
        XCTAssertEqual(probSum, 1.0, accuracy: 0.01)
    }

    func testPredictWithNormalHRFeatures() {
        // Given features for normal resting state
        // Mean HR=70, Std=5, Min=65, Max=75, SDNN=50, RMSSD=40
        let features = [70.0, 5.0, 65.0, 75.0, 50.0, 40.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then should return valid prediction
        XCTAssertNotNil(prediction.emotion)
        XCTAssertTrue(prediction.confidence > 0.0)
        XCTAssertTrue(["Amused", "Calm", "Stressed"].contains(prediction.emotion))
    }

    func testPredictWithStressedFeatures() {
        // Given features indicating stress
        // High HR, low HRV
        let features = [100.0, 15.0, 85.0, 115.0, 20.0, 15.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then should return valid prediction
        XCTAssertNotNil(prediction.emotion)
        XCTAssertTrue(prediction.confidence >= 0.0)
    }

    func testPredictWithCalmFeatures() {
        // Given features indicating calm state
        // Low HR, high HRV
        let features = [60.0, 5.0, 55.0, 65.0, 70.0, 60.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then should return valid prediction
        XCTAssertNotNil(prediction.emotion)
        XCTAssertTrue(prediction.confidence >= 0.0)
    }

    func testProbabilitiesAreValid() {
        // Given any features
        let features = [75.0, 10.0, 60.0, 90.0, 50.0, 40.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then all probabilities should be valid
        for (emotion, prob) in prediction.probabilities {
            XCTAssertTrue(prob >= 0.0, "\(emotion) probability should be >= 0")
            XCTAssertTrue(prob <= 1.0, "\(emotion) probability should be <= 1")
        }

        // And probabilities should sum to 1
        let sum = prediction.probabilities.values.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 0.01)
    }

    func testDominantEmotionMatchesHighestProbability() {
        // Given any features
        let features = [75.0, 10.0, 60.0, 90.0, 50.0, 40.0]

        // When predicting
        let prediction = svmPredictor.predict(features: features)

        // Then dominant emotion should have highest probability
        let maxProb = prediction.probabilities.max(by: { $0.value < $1.value })
        XCTAssertEqual(prediction.emotion, maxProb?.key)
        XCTAssertEqual(prediction.confidence, maxProb?.value ?? 0.0, accuracy: 0.001)
    }

    func testPredictionIsDeterministic() {
        // Given the same features
        let features = [75.0, 10.0, 60.0, 90.0, 50.0, 40.0]

        // When predicting multiple times
        let prediction1 = svmPredictor.predict(features: features)
        let prediction2 = svmPredictor.predict(features: features)

        // Then results should be identical
        XCTAssertEqual(prediction1.emotion, prediction2.emotion)
        XCTAssertEqual(prediction1.confidence, prediction2.confidence, accuracy: 0.0001)
    }
}
