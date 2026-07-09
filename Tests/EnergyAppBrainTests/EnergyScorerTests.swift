import XCTest
@testable import EnergyAppBrainCore

final class EnergyScorerTests: XCTestCase {
    func testBadSleepAndAlcoholProducesLowScore() {
        let input = scenario(named: "Bad sleep + alcohol")
        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertLessThan(result.scoreOutOf100, 40)
        XCTAssertEqual(result.predictedEnergyOutOf10, 2)
        XCTAssertTrue(result.breakdown.contains { $0.label == "Slept under 6 hours" })
        XCTAssertTrue(result.breakdown.contains { $0.label == "3 alcohol drinks" })
    }

    func testGoodRecoveryDayProducesHighScore() {
        let input = scenario(named: "Good recovery day")
        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertEqual(result.scoreOutOf100, 100)
        XCTAssertEqual(result.predictedEnergyOutOf10, 10)
    }

    func testHighStressWorkdayRecommendsLightTraining() {
        let input = scenario(named: "High stress workday")
        let result = EnergyScorer.calculateEnergy(input: input)

        let trainingRecommendation = recommendation(category: "Training", in: result)

        XCTAssertLessThan(result.scoreOutOf100, 40)
        XCTAssertTrue(trainingRecommendation.message.contains("Avoid intense training"))
    }

    func testHardTrainingDayWarnsAgainstAnotherMaxEffortSession() {
        let input = scenario(named: "Hard training day")
        let result = EnergyScorer.calculateEnergy(input: input)

        let trainingRecommendation = recommendation(category: "Training", in: result)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)

        XCTAssertEqual(result.predictedEnergyOutOf10, 8)
        XCTAssertTrue(trainingRecommendation.message.contains("Avoid another max-effort session"))
        XCTAssertTrue(recoveryRecommendation.message.contains("protect recovery"))
    }

    func testAlcoholPenaltyGetsHarsherAfterThreeDrinks() {
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 0), 0)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 1), -6)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 2), -12)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 3), -24)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 4), -36)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 6), -60)
    }

    func testLowHRVAndHighRestingHeartRateAddsRecoveryStrain() {
        let input = scenario(named: "High stress workday")
        let result = EnergyScorer.calculateEnergy(input: input)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Recovery strain" && $0.points == -10 })
        XCTAssertTrue(recoveryRecommendation.message.contains("Recovery looks compromised"))
    }

    func testLogSummaryCalculatesAveragesAndTrend() {
        let rows = [
            ["Day 1", "7.0", "0", "false", "6", "4", "60", "50", "8000", "4", "6", "5"],
            ["Day 2", "8.0", "0", "false", "8", "3", "58", "60", "9000", "3", "9", "8"],
            ["Day 3", "6.0", "1", "true", "5", "7", "", "", "5000", "2", "4", ""]
        ]

        let summary = DailyLogStore.makeLogSummary(from: rows)

        XCTAssertEqual(summary.totalLogs, 3)
        XCTAssertEqual(summary.completedLogs, 2)
        XCTAssertEqual(summary.missingActualEnergy, 1)
        XCTAssertEqual(summary.averagePredictedEnergy, 6.333333333333333)
        XCTAssertEqual(summary.averageActualEnergy, 6.5)
        XCTAssertEqual(summary.lowestActualEnergyDay, "Day 1")
        XCTAssertEqual(summary.highestActualEnergyDay, "Day 2")
        XCTAssertEqual(summary.recentTrend, "Improving")
    }

    func testRecentLogLinesShowNewestFirstAndMissingActualEnergy() {
        let rows = [
            ["Day 1", "7.0", "0", "false", "6", "4", "60", "50", "8000", "4", "6", "5"],
            ["Day 2", "8.0", "0", "false", "8", "3", "58", "60", "9000", "3", "9", "8"],
            ["Day 3", "6.0", "1", "true", "5", "7", "", "", "5000", "2", "4", ""]
        ]

        let lines = DailyLogStore.makeRecentLogLines(from: rows, count: 2)

        XCTAssertEqual(lines.count, 2)
        XCTAssertTrue(lines[0].contains("Day 3"))
        XCTAssertTrue(lines[0].contains("actual missing"))
        XCTAssertTrue(lines[1].contains("Day 2"))
        XCTAssertTrue(lines[1].contains("actual 8/10"))
    }

    private func scenario(named name: String) -> EnergyInput {
        guard let input = DemoData.makeDemoScenarios().first(where: { $0.dateLabel == name }) else {
            XCTFail("Missing scenario named \(name)")
            return DemoData.makeDemoScenarios()[0]
        }

        return input
    }

    private func recommendation(category: String, in result: EnergyResult) -> Recommendation {
        guard let recommendation = result.recommendations.first(where: { $0.category == category }) else {
            XCTFail("Missing \(category) recommendation")
            return Recommendation(category: category, message: "")
        }

        return recommendation
    }
}
