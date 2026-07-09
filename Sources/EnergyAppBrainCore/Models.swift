public struct EnergyInput {
    let dateLabel: String
    let sleepHours: Double
    let alcoholDrinks: Int
    let hadCaffeineAfter6pm: Bool
    let moodOutOf10: Int
    let stressOutOf10: Int
    let appleWatch: AppleWatchMetrics
}

public struct AppleWatchMetrics {
    let restingHeartRate: Int?
    let heartRateVariability: Double?
    let steps: Int?
    let activeEnergyBurned: Int?
    let exerciseMinutes: Int?
    let workoutIntensityOutOf10: Int?
}

public struct EnergyResult {
    let scoreOutOf100: Int
    let predictedEnergyOutOf10: Int
    let breakdown: [ScoreAdjustment]
    let recommendations: [Recommendation]
}

public struct ScoreAdjustment {
    let label: String
    let points: Int
}

public struct Recommendation {
    let category: String
    let message: String
}

public struct DailyEnergyLog {
    let dateLabel: String
    let input: EnergyInput
    let result: EnergyResult
    let actualEnergyOutOf10: Int?
}
