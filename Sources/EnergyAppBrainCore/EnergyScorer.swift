public struct EnergyScorer {
    public static func calculateEnergy(input: EnergyInput) -> EnergyResult {
        var breakdown: [ScoreAdjustment] = [
            ScoreAdjustment(label: "Starting baseline", points: 80)
        ]

        addSleepAdjustment(input: input, breakdown: &breakdown)
        addLifestyleAdjustments(input: input, breakdown: &breakdown)
        addAppleWatchAdjustments(input: input, breakdown: &breakdown)

        var score = breakdown.reduce(0) { total, adjustment in
            total + adjustment.points
        }
        score = max(0, min(100, score))

        let predictedEnergy = max(1, min(10, Int((Double(score) / 10.0).rounded())))
        let recommendations = RecommendationEngine.makeRecommendations(for: input, score: score)

        return EnergyResult(
            scoreOutOf100: score,
            predictedEnergyOutOf10: predictedEnergy,
            breakdown: breakdown,
            recommendations: recommendations
        )
    }

    private static func addSleepAdjustment(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        if input.sleepHours < 6 {
            breakdown.append(ScoreAdjustment(label: "Slept under 6 hours", points: -25))
        } else if input.sleepHours < 7 {
            breakdown.append(ScoreAdjustment(label: "Slept under 7 hours", points: -10))
        } else if input.sleepHours >= 8 {
            breakdown.append(ScoreAdjustment(label: "Slept 8+ hours", points: 5))
        }
    }

    private static func addLifestyleAdjustments(input: EnergyInput, breakdown: inout [ScoreAdjustment]) {
        if input.alcoholDrinks > 0 {
            breakdown.append(ScoreAdjustment(label: "\(input.alcoholDrinks) alcohol drinks", points: -input.alcoholDrinks * 8))
        }

        if input.hadCaffeineAfter6pm {
            breakdown.append(ScoreAdjustment(label: "Caffeine after 6pm", points: -10))
        }

        if input.stressOutOf10 >= 8 {
            breakdown.append(ScoreAdjustment(label: "Very high stress", points: -10))
        } else if input.stressOutOf10 >= 6 {
            breakdown.append(ScoreAdjustment(label: "High stress", points: -5))
        }

        if input.moodOutOf10 <= 3 {
            breakdown.append(ScoreAdjustment(label: "Low mood", points: -8))
        } else if input.moodOutOf10 >= 8 {
            breakdown.append(ScoreAdjustment(label: "Good mood", points: 5))
        }
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

        if let steps = input.appleWatch.steps {
            appendIfNeeded(label: "Steps", points: stepsAdjustment(for: steps), breakdown: &breakdown)
        }
    }

    private static func appendIfNeeded(label: String, points: Int, breakdown: inout [ScoreAdjustment]) {
        if points != 0 {
            breakdown.append(ScoreAdjustment(label: label, points: points))
        }
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

    private static func restingHeartRateAdjustment(for restingHeartRate: Int) -> Int {
        if restingHeartRate >= 80 {
            return -8
        }

        if restingHeartRate >= 70 {
            return -3
        }

        return 2
    }

    private static func heartRateVariabilityAdjustment(for heartRateVariability: Double) -> Int {
        if heartRateVariability < 30 {
            return -8
        }

        if heartRateVariability < 45 {
            return -3
        }

        return 4
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
}
