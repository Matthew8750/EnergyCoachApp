public struct EnergyInput {
    public let dateLabel: String
    public let sleepHours: Double
    public let alcoholDrinks: Int
    public let previousNightAlcoholDrinks: Int
    public let hadCaffeineAfter6pm: Bool
    public let hoursSinceLateCaffeine: Double?
    public let moodOutOf10: Int
    public let stressOutOf10: Int
    public let illnessSeverityOutOf10: Int
    public let sleepQuality: SleepQualityMetrics?
    public let appleWatch: AppleWatchMetrics
    public let dietaryEnergyConsumed: Int?
    public let hoursAwake: Double?
    public let bodyProfile: BodyProfile?
    public let personalBaselines: PersonalBaselines?

    public init(
        dateLabel: String,
        sleepHours: Double,
        alcoholDrinks: Int,
        previousNightAlcoholDrinks: Int = 0,
        hadCaffeineAfter6pm: Bool,
        hoursSinceLateCaffeine: Double? = nil,
        moodOutOf10: Int,
        stressOutOf10: Int,
        illnessSeverityOutOf10: Int = 0,
        sleepQuality: SleepQualityMetrics? = nil,
        appleWatch: AppleWatchMetrics,
        dietaryEnergyConsumed: Int? = nil,
        hoursAwake: Double? = nil,
        bodyProfile: BodyProfile? = nil,
        personalBaselines: PersonalBaselines? = nil
    ) {
        self.dateLabel = dateLabel
        self.sleepHours = sleepHours
        self.alcoholDrinks = alcoholDrinks
        self.previousNightAlcoholDrinks = previousNightAlcoholDrinks
        self.hadCaffeineAfter6pm = hadCaffeineAfter6pm
        self.hoursSinceLateCaffeine = hoursSinceLateCaffeine
        self.moodOutOf10 = moodOutOf10
        self.stressOutOf10 = stressOutOf10
        self.illnessSeverityOutOf10 = illnessSeverityOutOf10
        self.sleepQuality = sleepQuality
        self.appleWatch = appleWatch
        self.dietaryEnergyConsumed = dietaryEnergyConsumed
        self.hoursAwake = hoursAwake
        self.bodyProfile = bodyProfile
        self.personalBaselines = personalBaselines
    }
}

public struct SleepQualityMetrics: Equatable, Sendable {
    public let deepSleepHours: Double?
    public let remSleepHours: Double?
    public let coreSleepHours: Double?
    public let awakeDuringSleepHours: Double?
    public let sleepEfficiency: Double?

    public init(
        deepSleepHours: Double?,
        remSleepHours: Double?,
        coreSleepHours: Double?,
        awakeDuringSleepHours: Double?,
        sleepEfficiency: Double?
    ) {
        self.deepSleepHours = deepSleepHours
        self.remSleepHours = remSleepHours
        self.coreSleepHours = coreSleepHours
        self.awakeDuringSleepHours = awakeDuringSleepHours
        self.sleepEfficiency = sleepEfficiency
    }
}

public struct BodyProfile: Equatable, Sendable {
    public let age: Int?
    public let biologicalSex: BiologicalSex?
    public let heightCentimeters: Double?
    public let weightKilograms: Double?

    public init(
        age: Int?,
        biologicalSex: BiologicalSex?,
        heightCentimeters: Double?,
        weightKilograms: Double?
    ) {
        self.age = age
        self.biologicalSex = biologicalSex
        self.heightCentimeters = heightCentimeters
        self.weightKilograms = weightKilograms
    }

    public var bodyMassIndex: Double? {
        guard
            let heightCentimeters,
            let weightKilograms,
            heightCentimeters > 0
        else {
            return nil
        }

        let heightMeters = heightCentimeters / 100
        return weightKilograms / (heightMeters * heightMeters)
    }

    public var estimatedBasalMetabolicRate: Double? {
        guard
            let age,
            let biologicalSex,
            let heightCentimeters,
            let weightKilograms
        else {
            return nil
        }

        let sexAdjustment: Double
        switch biologicalSex {
        case .female:
            sexAdjustment = -161
        case .male:
            sexAdjustment = 5
        case .other, .notSet:
            return nil
        }

        return (10 * weightKilograms) + (6.25 * heightCentimeters) - (5 * Double(age)) + sexAdjustment
    }

    public var estimatedMaxHeartRate: Int? {
        guard let age else {
            return nil
        }

        return Int((208 - (0.7 * Double(age))).rounded())
    }
}

public struct PersonalBaselines: Equatable, Sendable {
    public let sleepHours: Double?
    public let restingHeartRate: Int?
    public let heartRateVariability: Double?
    public let activeEnergyBurned: Int?

    public init(
        sleepHours: Double?,
        restingHeartRate: Int?,
        heartRateVariability: Double?,
        activeEnergyBurned: Int?
    ) {
        self.sleepHours = sleepHours
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.activeEnergyBurned = activeEnergyBurned
    }
}

public enum BiologicalSex: String, Equatable, Sendable {
    case female = "Female"
    case male = "Male"
    case other = "Other"
    case notSet = "Not set"
}

public struct AppleWatchMetrics {
    public let restingHeartRate: Int?
    public let heartRateVariability: Double?
    public let respiratoryRate: Double?
    public let oxygenSaturation: Double?
    public let walkingHeartRateAverage: Int?
    public let steps: Int?
    public let activeEnergyBurned: Int?
    public let exerciseMinutes: Int?
    public let standMinutes: Int?
    public let workoutIntensityOutOf10: Int?

    public init(
        restingHeartRate: Int?,
        heartRateVariability: Double?,
        respiratoryRate: Double? = nil,
        oxygenSaturation: Double? = nil,
        walkingHeartRateAverage: Int? = nil,
        steps: Int?,
        activeEnergyBurned: Int?,
        exerciseMinutes: Int?,
        standMinutes: Int? = nil,
        workoutIntensityOutOf10: Int?
    ) {
        self.restingHeartRate = restingHeartRate
        self.heartRateVariability = heartRateVariability
        self.respiratoryRate = respiratoryRate
        self.oxygenSaturation = oxygenSaturation
        self.walkingHeartRateAverage = walkingHeartRateAverage
        self.steps = steps
        self.activeEnergyBurned = activeEnergyBurned
        self.exerciseMinutes = exerciseMinutes
        self.standMinutes = standMinutes
        self.workoutIntensityOutOf10 = workoutIntensityOutOf10
    }
}

public struct EnergyResult {
    public let scoreOutOf100: Int
    public let predictedEnergyOutOf10: Int
    public let recoveryRisk: RecoveryRisk
    public let breakdown: [ScoreAdjustment]
    public let recommendations: [Recommendation]

    public init(
        scoreOutOf100: Int,
        predictedEnergyOutOf10: Int,
        recoveryRisk: RecoveryRisk,
        breakdown: [ScoreAdjustment],
        recommendations: [Recommendation]
    ) {
        self.scoreOutOf100 = scoreOutOf100
        self.predictedEnergyOutOf10 = predictedEnergyOutOf10
        self.recoveryRisk = recoveryRisk
        self.breakdown = breakdown
        self.recommendations = recommendations
    }
}

public enum RecoveryRisk: String {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"

    public var summary: String {
        switch self {
        case .low:
            return "Recovery risk looks low."
        case .moderate:
            return "Recovery risk is moderate."
        case .high:
            return "Recovery risk is high."
        }
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
