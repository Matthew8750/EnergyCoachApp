import XCTest
@testable import EnergyAppBrainCore

final class EnergyScorerTests: XCTestCase {
    func testBadSleepAndAlcoholProducesLowScore() {
        let input = scenario(named: "Bad sleep + alcohol")
        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertLessThan(result.scoreOutOf100, 40)
        XCTAssertEqual(result.predictedEnergyOutOf10, 1)
        XCTAssertEqual(result.recoveryRisk, .high)
        XCTAssertTrue(result.breakdown.contains { $0.label == "Slept under 6 hours" })
        XCTAssertTrue(result.breakdown.contains { $0.label == "3 alcohol drinks" })
    }

    func testGoodRecoveryDayProducesHighScore() {
        let input = scenario(named: "Good recovery day")
        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertGreaterThanOrEqual(result.scoreOutOf100, 90)
        XCTAssertEqual(result.predictedEnergyOutOf10, 9)
        XCTAssertEqual(result.recoveryRisk, .low)
    }

    func testHighStressWorkdayRecommendsLightTraining() {
        let input = scenario(named: "High stress workday")
        let result = EnergyScorer.calculateEnergy(input: input)

        let trainingRecommendation = recommendation(category: "Training", in: result)

        XCTAssertLessThan(result.scoreOutOf100, 40)
        XCTAssertTrue(trainingRecommendation.message.contains("Avoid intense training"))
    }

    func testUnknownMoodAndStressAreNeutral() {
        let input = EnergyInput(
            dateLabel: "Unknown mood and stress",
            sleepHours: 7.5,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 0,
            stressOutOf10: 0,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: nil,
                heartRateVariability: nil,
                steps: nil,
                activeEnergyBurned: nil,
                exerciseMinutes: nil,
                workoutIntensityOutOf10: nil
            ),
            hoursAwake: nil
        )

        let result = EnergyScorer.calculateEnergy(input: input)
        let moodOrStressLabels = ["Low mood", "Good mood", "High stress", "Very high stress"]

        XCTAssertFalse(result.breakdown.contains { moodOrStressLabels.contains($0.label) })
    }

    func testHardTrainingDayWarnsAgainstAnotherMaxEffortSession() {
        let input = scenario(named: "Hard training day")
        let result = EnergyScorer.calculateEnergy(input: input)

        let trainingRecommendation = recommendation(category: "Training", in: result)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)

        XCTAssertEqual(result.predictedEnergyOutOf10, 7)
        XCTAssertTrue(trainingRecommendation.message.contains("Avoid another max-effort session"))
        XCTAssertTrue(recoveryRecommendation.message.contains("protect recovery"))
    }

    func testSameDayAlcoholPenaltyStaysModest() {
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 0), 0)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 1), -2)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 2), -4)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 3), -6)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 4), -7)
        XCTAssertEqual(EnergyScorer.alcoholAdjustment(for: 6), -9)
    }

    func testPreviousNightAlcoholHitsNextDayHarderThanSameDayAlcohol() {
        XCTAssertEqual(EnergyScorer.previousNightAlcoholAdjustment(for: 0), 0)
        XCTAssertEqual(EnergyScorer.previousNightAlcoholAdjustment(for: 1), -4)
        XCTAssertEqual(EnergyScorer.previousNightAlcoholAdjustment(for: 3), -12)
        XCTAssertEqual(EnergyScorer.previousNightAlcoholAdjustment(for: 5), -19)
    }

    func testBodyProfileCalculatesCalibrationMetrics() {
        let profile = BodyProfile(
            age: 30,
            biologicalSex: .male,
            heightCentimeters: 180,
            weightKilograms: 80
        )

        XCTAssertEqual(profile.estimatedMaxHeartRate, 187)
        XCTAssertEqual(Int(profile.estimatedBasalMetabolicRate?.rounded() ?? 0), 1780)
        XCTAssertEqual((profile.bodyMassIndex ?? 0).rounded(), 25)
    }

    func testActivityForBodySizeUsesEnergyRelativeToProfile() {
        let profile = BodyProfile(
            age: 30,
            biologicalSex: .male,
            heightCentimeters: 180,
            weightKilograms: 80
        )

        XCTAssertEqual(
            EnergyScorer.activityForBodySizeAdjustment(
                activeEnergyBurned: 40,
                bodyProfile: profile
            ),
            -4
        )
        XCTAssertEqual(
            EnergyScorer.activityForBodySizeAdjustment(
                activeEnergyBurned: 500,
                bodyProfile: profile
            ),
            5
        )
    }

    func testBodyProfileAdjustmentUsesAgeAndBodyMassIndex() {
        let youngerHealthyProfile = BodyProfile(
            age: 22,
            biologicalSex: .male,
            heightCentimeters: 180,
            weightKilograms: 75
        )
        let olderHigherBMIProfile = BodyProfile(
            age: 58,
            biologicalSex: .male,
            heightCentimeters: 170,
            weightKilograms: 101
        )

        XCTAssertEqual(EnergyScorer.bodyProfileAdjustment(for: youngerHealthyProfile), 2)
        XCTAssertEqual(EnergyScorer.bodyProfileAdjustment(for: olderHigherBMIProfile), -7)
        XCTAssertEqual(EnergyScorer.bodyProfileAdjustment(for: nil), 0)
    }

    func testFuelStatusUsesLoggedCaloriesWhenAvailable() {
        XCTAssertEqual(
            EnergyScorer.fuelStatusAdjustment(dietaryEnergyConsumed: nil, activeEnergyBurned: 700),
            0
        )
        XCTAssertEqual(
            EnergyScorer.fuelStatusAdjustment(dietaryEnergyConsumed: 800, activeEnergyBurned: 550),
            -8
        )
        XCTAssertEqual(
            EnergyScorer.fuelStatusAdjustment(dietaryEnergyConsumed: 2_100, activeEnergyBurned: 650),
            3
        )
    }

    func testPersonalBaselinesAdjustCurrentSignals() {
        XCTAssertEqual(EnergyScorer.sleepBaselineAdjustment(current: 6.2, baseline: 7.5), -5)
        XCTAssertEqual(EnergyScorer.restingHeartRateBaselineAdjustment(current: 72, baseline: 61), -10)
        XCTAssertEqual(EnergyScorer.heartRateVariabilityBaselineAdjustment(current: 34, baseline: 55), -12)
    }

    func testFuelLimiterCreatesCustomNutritionRecommendation() {
        let input = EnergyInput(
            dateLabel: "Under-fuelled",
            sleepHours: 7.5,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 0,
            stressOutOf10: 0,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 8_000,
                activeEnergyBurned: 600,
                exerciseMinutes: 30,
                workoutIntensityOutOf10: 3
            ),
            dietaryEnergyConsumed: 800
        )

        let result = EnergyScorer.calculateEnergy(input: input)
        let nutritionRecommendation = recommendation(category: "Nutrition", in: result)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Fuel status" && $0.points == -8 })
        XCTAssertTrue(nutritionRecommendation.message.contains("Logged food looks low"))
    }

    func testFreshLateCaffeineBoostsCurrentEnergyButRaisesRecoveryRisk() {
        let input = EnergyInput(
            dateLabel: "Fresh caffeine",
            sleepHours: 8.0,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: true,
            hoursSinceLateCaffeine: 1,
            moodOutOf10: 7,
            stressOutOf10: 3,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 8_000,
                activeEnergyBurned: 500,
                exerciseMinutes: 30,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 11
        )

        let result = EnergyScorer.calculateEnergy(input: input)
        let caffeineRecommendation = recommendation(category: "Caffeine", in: result)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Late caffeine current effect" && $0.points == 6 })
        XCTAssertEqual(result.recoveryRisk, .low)
        XCTAssertTrue(caffeineRecommendation.message.contains("boosting current energy"))
    }

    func testLateCaffeineEventuallyDragsCurrentEnergy() {
        XCTAssertEqual(
            EnergyScorer.lateCaffeineCurrentEnergyAdjustment(
                hadCaffeineAfter6pm: true,
                hoursSinceLateCaffeine: 7
            ),
            -6
        )
    }

    func testIllnessStronglyReducesEnergyAndRaisesRecoveryRisk() {
        let input = EnergyInput(
            dateLabel: "Sick day",
            sleepHours: 8.0,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 7,
            stressOutOf10: 3,
            illnessSeverityOutOf10: 7,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 62,
                heartRateVariability: 55,
                steps: 4_000,
                activeEnergyBurned: 250,
                exerciseMinutes: 10,
                workoutIntensityOutOf10: 1
            ),
            hoursAwake: 6
        )

        let result = EnergyScorer.calculateEnergy(input: input)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)
        let trainingRecommendation = recommendation(category: "Training", in: result)

        XCTAssertLessThan(result.scoreOutOf100, 50)
        XCTAssertEqual(result.recoveryRisk, .high)
        XCTAssertTrue(result.breakdown.contains { $0.label == "Illness / symptoms" && $0.points == -35 })
        XCTAssertTrue(recoveryRecommendation.message.contains("main limiter"))
        XCTAssertTrue(trainingRecommendation.message.contains("Skip hard training"))
    }

    func testHeavyAlcoholRaisesRecoveryRiskWithoutCrushingCurrentEnergy() {
        let input = EnergyInput(
            dateLabel: "Social evening",
            sleepHours: 8.0,
            alcoholDrinks: 5,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 8,
            stressOutOf10: 3,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 9_000,
                activeEnergyBurned: 600,
                exerciseMinutes: 35,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 11
        )

        let result = EnergyScorer.calculateEnergy(input: input)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)

        XCTAssertGreaterThanOrEqual(result.scoreOutOf100, 70)
        XCTAssertEqual(result.recoveryRisk, .high)
        XCTAssertFalse(recoveryRecommendation.message.isEmpty)
    }

    func testLongTimeAwakeReducesCurrentEnergy() {
        let input = EnergyInput(
            dateLabel: "Long day",
            sleepHours: 8.0,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 7,
            stressOutOf10: 3,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 8_000,
                activeEnergyBurned: 500,
                exerciseMinutes: 30,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 17
        )

        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Time awake" && $0.points == -45 })
        XCTAssertEqual(result.recoveryRisk, .low)
    }

    func testThirteenAndHalfHoursAwakeMeaningfullyReducesEnergy() {
        let input = EnergyInput(
            dateLabel: "Late evening",
            sleepHours: 8.0,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 7,
            stressOutOf10: 3,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 8_000,
                activeEnergyBurned: 500,
                exerciseMinutes: 30,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 13.5
        )

        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Time awake" && $0.points == -28 })
        XCTAssertLessThanOrEqual(result.scoreOutOf100, 70)
    }

    func testLateDayEnergyCeilingCapsUnrealisticallyHighEveningScore() {
        let input = EnergyInput(
            dateLabel: "Good evening",
            sleepHours: 8.2,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 8,
            stressOutOf10: 2,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 56,
                heartRateVariability: 68,
                steps: 12_000,
                activeEnergyBurned: 650,
                exerciseMinutes: 35,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 14.5,
            bodyProfile: BodyProfile(
                age: 30,
                biologicalSex: .male,
                heightCentimeters: 180,
                weightKilograms: 80
            )
        )

        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertLessThanOrEqual(result.scoreOutOf100, 75)
        XCTAssertTrue(result.breakdown.contains { $0.label == "Time awake" && $0.points == -35 })
    }

    func testVeryLongDayCapsScoreMoreAggressively() {
        let input = EnergyInput(
            dateLabel: "Very long day",
            sleepHours: 8.2,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 8,
            stressOutOf10: 2,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 56,
                heartRateVariability: 68,
                steps: 12_000,
                activeEnergyBurned: 650,
                exerciseMinutes: 35,
                workoutIntensityOutOf10: 3
            ),
            hoursAwake: 18.2
        )

        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertLessThanOrEqual(result.scoreOutOf100, 40)
        XCTAssertTrue(result.breakdown.contains { $0.label == "Time awake" && $0.points == -55 })
    }

    func testSevenHoursAwakeAlreadyReducesCurrentEnergy() {
        let input = EnergyInput(
            dateLabel: "Normal morning",
            sleepHours: 8.0,
            alcoholDrinks: 0,
            hadCaffeineAfter6pm: false,
            moodOutOf10: 7,
            stressOutOf10: 3,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: 58,
                heartRateVariability: 60,
                steps: 5_000,
                activeEnergyBurned: 300,
                exerciseMinutes: 20,
                workoutIntensityOutOf10: 2
            ),
            hoursAwake: 7
        )

        let result = EnergyScorer.calculateEnergy(input: input)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Time awake" && $0.points == -3 })
    }

    func testLowHRVAndHighRestingHeartRateAddsRecoveryStrain() {
        let input = scenario(named: "High stress workday")
        let result = EnergyScorer.calculateEnergy(input: input)
        let recoveryRecommendation = recommendation(category: "Recovery", in: result)

        XCTAssertTrue(result.breakdown.contains { $0.label == "Recovery strain" && $0.points == -10 })
        XCTAssertFalse(recoveryRecommendation.message.isEmpty)
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

    func testReadableLogFileFallsBackToExampleWhenPrivateLogIsMissing() {
        let selectedFile = DailyLogStore.readableLogFileName(
            preferredFileName: "energy_logs.csv",
            fallbackFileName: "energy_logs.example.csv",
            fileExists: { $0 == "energy_logs.example.csv" }
        )

        XCTAssertEqual(selectedFile, "energy_logs.example.csv")
    }

    func testReadableLogFilePrefersPrivateLogWhenAvailable() {
        let selectedFile = DailyLogStore.readableLogFileName(
            preferredFileName: "energy_logs.csv",
            fallbackFileName: "energy_logs.example.csv",
            fileExists: { $0 == "energy_logs.csv" }
        )

        XCTAssertEqual(selectedFile, "energy_logs.csv")
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
