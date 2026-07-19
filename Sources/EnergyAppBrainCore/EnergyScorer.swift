public struct EnergyScorer {
    public static func calculateEnergy(input: EnergyInput) -> EnergyResult {
        var breakdown: [ScoreAdjustment] = [
            ScoreAdjustment(label: "Starting baseline", points: 50)
        ]

        addSleepAdjustment(input: input, breakdown: &breakdown)
        addSleepQualityAdjustments(input: input, breakdown: &breakdown)
        addLifestyleAdjustments(input: input, breakdown: &breakdown)
        addAppleWatchAdjustments(input: input, breakdown: &breakdown)
        addPersonalBaselineAdjustments(input: input, breakdown: &breakdown)
        addFuelAdjustments(input: input, breakdown: &breakdown)

        var score = breakdown.reduce(0) { total, adjustment in
            total + adjustment.points
        }
        score = capScoreForTimeAwake(score, hoursAwake: input.hoursAwake, breakdown: &breakdown)
        score = max(0, min(100, score))

        let predictedEnergy = max(1, min(10, Int((Double(score) / 10.0).rounded())))
        let recoveryRisk = calculateRecoveryRisk(input: input, score: score)
        let recommendations = RecommendationEngine.makeRecommendations(for: input, score: score, breakdown: breakdown)

        return EnergyResult(
            scoreOutOf100: score,
            predictedEnergyOutOf10: predictedEnergy,
            recoveryRisk: recoveryRisk,
            breakdown: breakdown,
            recommendations: recommendations
        )
    }

    private static func addSleepAdjustment(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        if input.sleepHours < 6 {
            breakdown.append(ScoreAdjustment(label: "Slept under 6 hours", points: -30))
        } else if input.sleepHours < 7 {
            breakdown.append(ScoreAdjustment(label: "Slept under 7 hours", points: -15))
        } else if input.sleepHours < 8 {
            breakdown.append(ScoreAdjustment(label: "Slept 7+ hours", points: 8))
        } else if input.sleepHours >= 8 {
            breakdown.append(ScoreAdjustment(label: "Slept 8+ hours", points: 15))
        }
    }

    private static func addSleepQualityAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        guard let sleepQuality = input.sleepQuality else {
            return
        }

        appendIfNeeded(
            label: "Sleep efficiency",
            points: sleepEfficiencyAdjustment(for: sleepQuality.sleepEfficiency),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "Deep sleep",
            points: deepSleepAdjustment(for: sleepQuality.deepSleepHours),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "REM sleep",
            points: remSleepAdjustment(for: sleepQuality.remSleepHours),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "Awake during sleep",
            points: awakeDuringSleepAdjustment(for: sleepQuality.awakeDuringSleepHours),
            breakdown: &breakdown
        )
    }

    private static func addLifestyleAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        if input.alcoholDrinks > 0 {
            breakdown.append(ScoreAdjustment(label: "\(input.alcoholDrinks) alcohol drinks", points: alcoholAdjustment(for: input.alcoholDrinks)))
        }

        appendIfNeeded(
            label: "Previous night alcohol",
            points: previousNightAlcoholAdjustment(for: input.previousNightAlcoholDrinks),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "Late caffeine current effect",
            points: lateCaffeineCurrentEnergyAdjustment(
                hadCaffeineAfter6pm: input.hadCaffeineAfter6pm,
                hoursSinceLateCaffeine: input.hoursSinceLateCaffeine
            ),
            breakdown: &breakdown
        )

        if input.stressOutOf10 >= 8 {
            breakdown.append(ScoreAdjustment(label: "Very high stress", points: -15))
        } else if input.stressOutOf10 >= 6 {
            breakdown.append(ScoreAdjustment(label: "High stress", points: -8))
        }

        if input.moodOutOf10 > 0 && input.moodOutOf10 <= 3 {
            breakdown.append(ScoreAdjustment(label: "Low mood", points: -12))
        } else if input.moodOutOf10 >= 8 {
            breakdown.append(ScoreAdjustment(label: "Good mood", points: 8))
        }

        appendIfNeeded(
            label: "Illness / symptoms",
            points: illnessAdjustment(for: input.illnessSeverityOutOf10),
            breakdown: &breakdown
        )

        if let hoursAwake = input.hoursAwake {
            appendIfNeeded(label: "Time awake", points: timeAwakeAdjustment(for: hoursAwake), breakdown: &breakdown)
        }

        appendIfNeeded(
            label: "Body profile calibration",
            points: bodyProfileAdjustment(for: input.bodyProfile),
            breakdown: &breakdown
        )
    }

    private static func addAppleWatchAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        if let workoutIntensity = input.appleWatch.workoutIntensityOutOf10 {
            appendIfNeeded(label: "Workout intensity", points: workoutAdjustment(for: workoutIntensity), breakdown: &breakdown)
        }

        if let restingHeartRate = input.appleWatch.restingHeartRate {
            appendIfNeeded(label: "Resting heart rate", points: restingHeartRateAdjustment(for: restingHeartRate), breakdown: &breakdown)
        }

        if let heartRateVariability = input.appleWatch.heartRateVariability {
            appendIfNeeded(label: "Heart rate variability", points: heartRateVariabilityAdjustment(for: heartRateVariability), breakdown: &breakdown)
        }

        if let respiratoryRate = input.appleWatch.respiratoryRate {
            appendIfNeeded(label: "Respiratory rate", points: respiratoryRateAdjustment(for: respiratoryRate), breakdown: &breakdown)
        }

        if let oxygenSaturation = input.appleWatch.oxygenSaturation {
            appendIfNeeded(label: "Blood oxygen", points: oxygenSaturationAdjustment(for: oxygenSaturation), breakdown: &breakdown)
        }

        if let walkingHeartRateAverage = input.appleWatch.walkingHeartRateAverage {
            appendIfNeeded(label: "Walking heart rate", points: walkingHeartRateAdjustment(for: walkingHeartRateAverage), breakdown: &breakdown)
        }

        if let steps = input.appleWatch.steps {
            appendIfNeeded(label: "Steps", points: stepsAdjustment(for: steps), breakdown: &breakdown)
        }

        if let standMinutes = input.appleWatch.standMinutes {
            appendIfNeeded(label: "Stand time", points: standMinutesAdjustment(for: standMinutes), breakdown: &breakdown)
        }

        appendIfNeeded(
            label: "Activity for body size",
            points: activityForBodySizeAdjustment(
                activeEnergyBurned: input.appleWatch.activeEnergyBurned,
                bodyProfile: input.bodyProfile
            ),
            breakdown: &breakdown
        )

        appendIfNeeded(label: "Recovery strain", points: recoveryStrainAdjustment(for: input.appleWatch), breakdown: &breakdown)
    }

    private static func addPersonalBaselineAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        guard let baselines = input.personalBaselines else {
            return
        }

        appendIfNeeded(
            label: "Sleep vs baseline",
            points: sleepBaselineAdjustment(current: input.sleepHours, baseline: baselines.sleepHours),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "Resting HR vs baseline",
            points: restingHeartRateBaselineAdjustment(
                current: input.appleWatch.restingHeartRate,
                baseline: baselines.restingHeartRate
            ),
            breakdown: &breakdown
        )

        appendIfNeeded(
            label: "HRV vs baseline",
            points: heartRateVariabilityBaselineAdjustment(
                current: input.appleWatch.heartRateVariability,
                baseline: baselines.heartRateVariability
            ),
            breakdown: &breakdown
        )
    }

    private static func addFuelAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        appendIfNeeded(
            label: "Fuel status",
            points: fuelStatusAdjustment(
                dietaryEnergyConsumed: input.dietaryEnergyConsumed,
                activeEnergyBurned: input.appleWatch.activeEnergyBurned
            ),
            breakdown: &breakdown
        )
    }

    private static func appendIfNeeded(label: String, points: Int, breakdown: inout [ScoreAdjustment]) {
        if points != 0 {
            breakdown.append(ScoreAdjustment(label: label, points: points))
        }
    }

    public static func alcoholAdjustment(for drinks: Int) -> Int {
        if drinks <= 0 {
            return 0
        }

        if drinks <= 3 {
            return drinks * -2
        }

        return -6 - (drinks - 3)
    }

    public static func previousNightAlcoholAdjustment(for drinks: Int) -> Int {
        if drinks <= 0 {
            return 0
        }

        if drinks <= 2 {
            return drinks * -4
        }

        if drinks <= 4 {
            return -8 - ((drinks - 2) * 4)
        }

        return -16 - ((drinks - 4) * 3)
    }

    public static func alcoholRecoveryRiskPoints(for drinks: Int) -> Int {
        if drinks <= 0 {
            return 0
        }

        if drinks <= 2 {
            return drinks * 10
        }

        if drinks <= 4 {
            return 25 + ((drinks - 2) * 12)
        }

        return 55 + ((drinks - 4) * 10)
    }

    public static func illnessAdjustment(for severity: Int) -> Int {
        let clampedSeverity = max(0, min(10, severity))

        if clampedSeverity == 0 {
            return 0
        }

        if clampedSeverity <= 3 {
            return -8 - (clampedSeverity * 2)
        }

        if clampedSeverity <= 6 {
            return -18 - ((clampedSeverity - 3) * 4)
        }

        return -30 - ((clampedSeverity - 6) * 5)
    }

    public static func lateCaffeineCurrentEnergyAdjustment(
        hadCaffeineAfter6pm: Bool,
        hoursSinceLateCaffeine: Double?
    ) -> Int {
        guard hadCaffeineAfter6pm, let hoursSinceLateCaffeine else {
            return 0
        }

        if hoursSinceLateCaffeine <= 0.5 {
            return 3
        }

        if hoursSinceLateCaffeine <= 2 {
            return 6
        }

        if hoursSinceLateCaffeine <= 4 {
            return 2
        }

        if hoursSinceLateCaffeine <= 6 {
            return -3
        }

        return -6
    }

    public static func calculateRecoveryRisk(input: EnergyInput, score: Int) -> RecoveryRisk {
        var points = 0

        points += alcoholRecoveryRiskPoints(for: input.alcoholDrinks)
        points += alcoholRecoveryRiskPoints(for: input.previousNightAlcoholDrinks)

        if input.hadCaffeineAfter6pm {
            points += 15
        }

        if input.sleepHours < 6 {
            points += 25
        } else if input.sleepHours < 7 {
            points += 10
        }

        if sleepEfficiencyAdjustment(for: input.sleepQuality?.sleepEfficiency) < 0 {
            points += 10
        }

        if input.stressOutOf10 >= 8 {
            points += 15
        } else if input.stressOutOf10 >= 6 {
            points += 8
        }

        if input.illnessSeverityOutOf10 > 0 {
            points += min(60, 15 + (input.illnessSeverityOutOf10 * 7))
        }

        if recoveryStrainAdjustment(for: input.appleWatch) < 0 {
            points += 25
        }

        if respiratoryRateAdjustment(for: input.appleWatch.respiratoryRate ?? 0) < 0 {
            points += 10
        }

        if oxygenSaturationAdjustment(for: input.appleWatch.oxygenSaturation ?? 1) < 0 {
            points += 15
        }

        if input.appleWatch.workoutIntensityOutOf10 ?? 0 >= 8 {
            points += 15
        }

        if fuelStatusAdjustment(
            dietaryEnergyConsumed: input.dietaryEnergyConsumed,
            activeEnergyBurned: input.appleWatch.activeEnergyBurned
        ) < 0 {
            points += 8
        }

        if (input.hoursAwake ?? 0) >= 16 {
            points += 10
        }

        if score < 40 {
            points += 10
        }

        if points >= 55 {
            return .high
        }

        if points >= 25 {
            return .moderate
        }

        return .low
    }

    public static func recoveryStrainAdjustment(for metrics: AppleWatchMetrics) -> Int {
        guard
            let restingHeartRate = metrics.restingHeartRate,
            let heartRateVariability = metrics.heartRateVariability
        else {
            return 0
        }

        if heartRateVariability < 30 && restingHeartRate >= 75 {
            return -10
        }

        return 0
    }

    private static func workoutAdjustment(for workoutIntensity: Int) -> Int {
        if workoutIntensity >= 8 {
            return -8
        }

        if workoutIntensity >= 5 {
            return -3
        }

        if workoutIntensity >= 2 {
            return 2
        }

        return 0
    }

    private static func timeAwakeAdjustment(for hoursAwake: Double) -> Int {
        if hoursAwake >= 20 {
            return -65
        }

        if hoursAwake >= 18 {
            return -55
        }

        if hoursAwake >= 16 {
            return -45
        }

        if hoursAwake >= 14 {
            return -35
        }

        if hoursAwake >= 13 {
            return -28
        }

        if hoursAwake >= 12 {
            return -20
        }

        if hoursAwake >= 9 {
            return -12
        }

        if hoursAwake >= 6 {
            return -3
        }

        if hoursAwake >= 2 {
            return 2
        }

        if hoursAwake < 2 {
            return -5
        }

        return 0
    }

    private static func capScoreForTimeAwake(
        _ score: Int,
        hoursAwake: Double?,
        breakdown: inout [ScoreAdjustment]
    ) -> Int {
        guard let hoursAwake else {
            return score
        }

        let cap: Int
        if hoursAwake >= 20 {
            cap = 30
        } else if hoursAwake >= 18 {
            cap = 40
        } else if hoursAwake >= 16 {
            cap = 50
        } else if hoursAwake >= 14 {
            cap = 60
        } else if hoursAwake >= 13 {
            cap = 70
        } else {
            return score
        }

        guard score > cap else {
            return score
        }

        breakdown.append(ScoreAdjustment(label: "Late-day energy ceiling", points: cap - score))
        return cap
    }

    private static func restingHeartRateAdjustment(for restingHeartRate: Int) -> Int {
        if restingHeartRate >= 80 {
            return -12
        }

        if restingHeartRate >= 70 {
            return -6
        }

        return 5
    }

    private static func heartRateVariabilityAdjustment(for heartRateVariability: Double) -> Int {
        if heartRateVariability < 30 {
            return -12
        }

        if heartRateVariability < 45 {
            return -6
        }

        return 8
    }

    private static func sleepEfficiencyAdjustment(for sleepEfficiency: Double?) -> Int {
        guard let sleepEfficiency else {
            return 0
        }

        if sleepEfficiency < 0.72 {
            return -14
        }

        if sleepEfficiency < 0.82 {
            return -8
        }

        if sleepEfficiency >= 0.92 {
            return 5
        }

        return 0
    }

    private static func deepSleepAdjustment(for deepSleepHours: Double?) -> Int {
        guard let deepSleepHours else {
            return 0
        }

        if deepSleepHours < 0.6 {
            return -8
        }

        if deepSleepHours >= 1.5 {
            return 5
        }

        return 0
    }

    private static func remSleepAdjustment(for remSleepHours: Double?) -> Int {
        guard let remSleepHours else {
            return 0
        }

        if remSleepHours < 0.8 {
            return -6
        }

        if remSleepHours >= 1.5 {
            return 4
        }

        return 0
    }

    private static func awakeDuringSleepAdjustment(for awakeDuringSleepHours: Double?) -> Int {
        guard let awakeDuringSleepHours else {
            return 0
        }

        if awakeDuringSleepHours >= 1.5 {
            return -12
        }

        if awakeDuringSleepHours >= 0.75 {
            return -6
        }

        return 0
    }

    private static func respiratoryRateAdjustment(for respiratoryRate: Double) -> Int {
        if respiratoryRate <= 0 {
            return 0
        }

        if respiratoryRate >= 22 {
            return -10
        }

        if respiratoryRate >= 20 {
            return -5
        }

        return 0
    }

    private static func oxygenSaturationAdjustment(for oxygenSaturation: Double) -> Int {
        if oxygenSaturation <= 0 {
            return 0
        }

        if oxygenSaturation < 0.92 {
            return -14
        }

        if oxygenSaturation < 0.95 {
            return -7
        }

        return 0
    }

    private static func walkingHeartRateAdjustment(for walkingHeartRateAverage: Int) -> Int {
        if walkingHeartRateAverage >= 125 {
            return -8
        }

        if walkingHeartRateAverage >= 110 {
            return -4
        }

        return 0
    }

    private static func stepsAdjustment(for steps: Int) -> Int {
        if steps < 2_000 {
            return -5
        }

        if steps >= 8_000 {
            return 4
        }

        return 0
    }

    private static func standMinutesAdjustment(for standMinutes: Int) -> Int {
        if standMinutes < 120 {
            return -6
        }

        if standMinutes >= 360 {
            return 3
        }

        return 0
    }

    public static func bodyProfileAdjustment(for profile: BodyProfile?) -> Int {
        guard let profile else {
            return 0
        }

        var points = 0

        if let age = profile.age {
            if age >= 55 {
                points -= 4
            } else if age >= 40 {
                points -= 2
            } else if age <= 24 {
                points += 2
            }
        }

        if let bmi = profile.bodyMassIndex {
            if bmi < 18.5 {
                points -= 2
            } else if bmi >= 35 {
                points -= 5
            } else if bmi >= 30 {
                points -= 3
            } else if bmi >= 25 {
                points -= 1
            }
        }

        return max(-7, min(3, points))
    }

    public static func activityForBodySizeAdjustment(
        activeEnergyBurned: Int?,
        bodyProfile: BodyProfile?
    ) -> Int {
        guard
            let activeEnergyBurned,
            let basalMetabolicRate = bodyProfile?.estimatedBasalMetabolicRate,
            basalMetabolicRate > 0
        else {
            return 0
        }

        let activityRatio = Double(activeEnergyBurned) / basalMetabolicRate

        if activityRatio < 0.05 {
            return -4
        }

        if activityRatio >= 0.25 {
            return 5
        }

        if activityRatio >= 0.15 {
            return 3
        }

        return 0
    }

    public static func fuelStatusAdjustment(
        dietaryEnergyConsumed: Int?,
        activeEnergyBurned: Int?
    ) -> Int {
        guard
            let dietaryEnergyConsumed,
            dietaryEnergyConsumed > 0,
            let activeEnergyBurned
        else {
            return 0
        }

        if dietaryEnergyConsumed < 900 && activeEnergyBurned >= 500 {
            return -8
        }

        if dietaryEnergyConsumed < 1_300 && activeEnergyBurned >= 700 {
            return -6
        }

        if dietaryEnergyConsumed >= 1_800 && activeEnergyBurned >= 500 {
            return 3
        }

        return 0
    }

    public static func sleepBaselineAdjustment(current: Double, baseline: Double?) -> Int {
        guard let baseline, baseline > 0 else {
            return 0
        }

        let difference = current - baseline

        if difference <= -1.5 {
            return -10
        }

        if difference <= -0.75 {
            return -5
        }

        if difference >= 0.75 {
            return 4
        }

        return 0
    }

    public static func restingHeartRateBaselineAdjustment(current: Int?, baseline: Int?) -> Int {
        guard let current, let baseline, baseline > 0 else {
            return 0
        }

        let difference = current - baseline

        if difference >= 10 {
            return -10
        }

        if difference >= 6 {
            return -6
        }

        if difference <= -5 {
            return 3
        }

        return 0
    }

    public static func heartRateVariabilityBaselineAdjustment(current: Double?, baseline: Double?) -> Int {
        guard let current, let baseline, baseline > 0 else {
            return 0
        }

        let ratio = current / baseline

        if ratio <= 0.65 {
            return -12
        }

        if ratio <= 0.8 {
            return -7
        }

        if ratio >= 1.15 {
            return 5
        }

        return 0
    }
}
