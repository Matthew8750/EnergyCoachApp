public struct EnergyInput {
    public let dateLabel: String
    public let sleepHours: Double
    public let alcoholDrinks: Int
    public let hadCaffeineAfter6pm: Bool
    public let moodOutOf10: Int
    public let stressOutOf10: Int
    public let appleWatch: AppleWatchMetrics

    public init(
        dateLabel: String,
        sleepHours: Double,
        alcoholDrinks: Int,
        hadCaffeineAfter6pm: Bool,
        moodOutOf10: Int,
        stressOutOf10: Int,
        appleWatch: AppleWatchMetrics
    ) {
        self.dateLabel = dateLabel
        self.sleepHours = sleepHours
        self.alcoholDrinks = alcoholDrinks
        self.hadCaffeineAfter6pm = hadCaffeineAfter6pm
        self.moodOutOf10 = moodOutOf10
        self.stressOutOf10 = stressOutOf10
        self.appleWatch = appleWatch
    }
}

public struct AppleWatchMetrics {
    public let restingHeartRate: Int?
    public let heartRateVariability: Double?
    public let steps: Int?
    public let activeEnergyBurned: Int?
    public let exerciseMinutes: Int?
    public let workoutIntensityOutOf10: Int?

    public init(
        restingHeartRate: Int?,
        heartRateVariability: Double?,
        steps: Int?,
        activeEnergyBurned: Int?,
        exerciseMinutes: Int?,
        workoutIntensityOutOf10: Int?
    ) {
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.steps = steps
        self.activeEnergyBurned = activeEnergyBurned
        self.exerciseMinutes = exerciseMinutes
        self.workoutIntensityOutOf10 = workoutIntensityOutOf10
    }
}

public struct EnergyResult {
    public let scoreOutOf100: Int
    public let predictedEnergyOutOf10: Int
    public let breakdown: [ScoreAdjustment]
    public let recommendations: [Recommendation]

    public init(
        scoreOutOf100: Int,
        predictedEnergyOutOf10: Int,
        breakdown: [ScoreAdjustment],
        recommendations: [Recommendation]
    ) {
        self.scoreOutOf100 = scoreOutOf100
        self.predictedEnergyOutOf10 = predictedEnergyOutOf10
        self.breakdown = breakdown
        self.recommendations = recommendations
    }
}

public struct ScoreAdjustment {
    public let label: String
    public let points: Int

    public init(label: String, points: Int) {
        self.label = label
        self.points = points
    }
}

public struct Recommendation {
    public let category: String
    public let message: String

    public init(category: String, message: String) {
        self.category = category
        self.message = message
    }
}

public struct DailyEnergyLog {
    public let dateLabel: String
    public let input: EnergyInput
    public let result: EnergyResult
    public let actualEnergyOutOf10: Int?

    public init(
        dateLabel: String,
        input: EnergyInput,
        result: EnergyResult,
        actualEnergyOutOf10: Int?
    ) {
        self.dateLabel = dateLabel
        self.input = input
        self.result = result
        self.actualEnergyOutOf10 = actualEnergyOutOf10
    }
}

public struct LogSummary {
    public let totalLogs: Int
    public let completedLogs: Int
    public let missingActualEnergy: Int
    public let averagePredictedEnergy: Double?
    public let averageActualEnergy: Double?
    public let lowestActualEnergyDay: String?
    public let highestActualEnergyDay: String?
    public let recentTrend: String
}
