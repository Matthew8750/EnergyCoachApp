struct EnergyInput {
    let dateLabel: String
    let sleepHours: Double
    let alcoholDrinks: Int
    let hadCaffeineAfter6pm: Bool
    let moodOutOf10: Int
    let stressOutOf10: Int
    let appleWatch: AppleWatchMetrics
}

struct AppleWatchMetrics {
    let restingHeartRate: Int?
    let heartRateVariability: Double?
    let steps: Int?
    let activeEnergyBurned: Int?
    let exerciseMinutes: Int?
    let workoutIntensityOutOf10: Int?
}

struct EnergyResult {
    let scoreOutOf100: Int
    let predictedEnergyOutOf10: Int
    let breakdown: [ScoreAdjustment]
    let recommendations: [Recommendation]
}

struct ScoreAdjustment {
    let label: String
    let points: Int
}

struct Recommendation {
    let category: String
    let message: String
}

struct DailyEnergyLog {
    let dateLabel: String
    let input: EnergyInput
    let result: EnergyResult
    let actualEnergyOutOf10: Int?
}
