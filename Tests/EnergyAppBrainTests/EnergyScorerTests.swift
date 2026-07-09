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
