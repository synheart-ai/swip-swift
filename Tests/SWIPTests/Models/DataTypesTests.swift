import XCTest
@testable import SWIP

final class DataTypesTests: XCTestCase {

    func testConsentLevelAllowsHierarchy() {
        // onDevice allows only itself
        XCTAssertTrue(ConsentLevel.onDevice.allows(.onDevice))
        XCTAssertFalse(ConsentLevel.onDevice.allows(.localExport))
        XCTAssertFalse(ConsentLevel.onDevice.allows(.dashboardShare))

        // localExport allows itself and onDevice
        XCTAssertTrue(ConsentLevel.localExport.allows(.onDevice))
        XCTAssertTrue(ConsentLevel.localExport.allows(.localExport))
        XCTAssertFalse(ConsentLevel.localExport.allows(.dashboardShare))

        // dashboardShare allows all
        XCTAssertTrue(ConsentLevel.dashboardShare.allows(.onDevice))
        XCTAssertTrue(ConsentLevel.dashboardShare.allows(.localExport))
        XCTAssertTrue(ConsentLevel.dashboardShare.allows(.dashboardShare))
    }

    func testSwipScoreRangeContainsCorrectRanges() {
        XCTAssertTrue(SwipScoreRange.positive.contains(90.0))
        XCTAssertTrue(SwipScoreRange.neutral.contains(65.0))
        XCTAssertTrue(SwipScoreRange.mildStress.contains(45.0))
        XCTAssertTrue(SwipScoreRange.negative.contains(25.0))

        XCTAssertFalse(SwipScoreRange.positive.contains(70.0))
        XCTAssertFalse(SwipScoreRange.neutral.contains(85.0))
    }

    func testSwipScoreRangeForScoreClassification() {
        XCTAssertEqual(SwipScoreRange.forScore(85.0), .positive)
        XCTAssertEqual(SwipScoreRange.forScore(70.0), .neutral)
        XCTAssertEqual(SwipScoreRange.forScore(50.0), .mildStress)
        XCTAssertEqual(SwipScoreRange.forScore(30.0), .negative)
    }

    func testEmotionClassHasCorrectUtilities() {
        XCTAssertEqual(EmotionClass.amused.utility, 0.95, accuracy: 0.01)
        XCTAssertEqual(EmotionClass.calm.utility, 0.85, accuracy: 0.01)
        XCTAssertEqual(EmotionClass.focused.utility, 0.80, accuracy: 0.01)
        XCTAssertEqual(EmotionClass.neutral.utility, 0.70, accuracy: 0.01)
        XCTAssertEqual(EmotionClass.stressed.utility, 0.15, accuracy: 0.01)
    }

    func testSessionStateFlags() {
        XCTAssertTrue(SessionState.active.isActive)
        XCTAssertFalse(SessionState.idle.isActive)

        XCTAssertTrue(SessionState.idle.canStart)
        XCTAssertTrue(SessionState.ended.canStart)
        XCTAssertFalse(SessionState.active.canStart)

        XCTAssertTrue(SessionState.active.canStop)
        XCTAssertTrue(SessionState.starting.canStop)
        XCTAssertFalse(SessionState.idle.canStop)
    }

    func testDataQualityClassification() {
        XCTAssertEqual(DataQuality.forScore(0.9), .high)
        XCTAssertEqual(DataQuality.forScore(0.5), .medium)
        XCTAssertEqual(DataQuality.forScore(0.2), .low)

        XCTAssertTrue(DataQuality.high.isAcceptable)
        XCTAssertTrue(DataQuality.medium.isAcceptable)
        XCTAssertFalse(DataQuality.low.isAcceptable)
    }

    func testConsentRecordJSONSerialization() {
        let date = ISO8601DateFormatter().date(from: "2024-01-01T00:00:00Z")!
        let record = ConsentRecord(
            level: .localExport,
            grantedAt: date,
            reason: "Testing"
        )

        let json = record.toJSON()
        XCTAssertEqual(json["level"] as? Int, 1)
        XCTAssertEqual(json["level_name"] as? String, "localExport")
        XCTAssertEqual(json["granted_at"] as? String, "2024-01-01T00:00:00Z")
        XCTAssertEqual(json["reason"] as? String, "Testing")

        let restored = ConsentRecord.fromJSON(json)
        XCTAssertEqual(record.level, restored?.level)
        XCTAssertEqual(record.reason, restored?.reason)
    }
}
