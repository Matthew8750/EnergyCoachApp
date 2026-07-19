public struct RecommendationEngine {
    public static func makeRecommendations(
        for input: EnergyInput,
        score: Int,
        breakdown: [ScoreAdjustment] = []
    ) -> [Recommendation] {
        var recommendations = [
            Recommendation(category: "Recovery", message: makeRecoveryRecommendation(for: input, score: score, breakdown: breakdown))
        ]

        if shouldShowNutrition(input: input) {
            recommendations.append(Recommendation(category: "Nutrition", message: makeNutritionRecommendation(for: input, score: score)))
        }

        if shouldShowTraining(input: input, score: score) {
            recommendations.append(Recommendation(category: "Training", message: makeTrainingRecommendation(for: input, score: score)))
        }

        if shouldShowSleep(input: input) {
            recommendations.append(Recommendation(category: "Sleep", message: makeSleepRecommendation(for: input)))
        }

        if shouldShowCaffeine(input: input) {
            recommendations.append(Recommendation(category: "Caffeine", message: makeCaffeineRecommendation(for: input)))
        }

        if recommendations.count == 1 && score >= 70 {
            recommendations.append(Recommendation(category: "Training", message: makeTrainingRecommendation(for: input, score: score)))
        }

        return Array(recommendations.filter { !$0.message.isEmpty }.prefix(3))
    }

    private static func makeRecoveryRecommendation(
        for input: EnergyInput,
        score: Int,
        breakdown: [ScoreAdjustment]
    ) -> String {
        if let biggestLimiter = biggestLimiter(in: breakdown) {
            switch biggestLimiter.label {
            case "Time awake", "Late-day energy ceiling":
                return "Time awake is the main limiter. Keep the rest of the day lower-pressure and protect your wind-down."
            case "HRV vs baseline", "Heart rate variability", "Recovery strain":
                return "Your recovery signals look below normal. Treat today as a lower-strain day even if motivation feels okay."
            case "Resting HR vs baseline", "Resting heart rate":
                return "Resting heart rate is higher than ideal. Keep intensity sensible and watch for illness, dehydration, or poor sleep."
            case "Fuel status":
                return "Fuel is likely limiting energy. Prioritise a proper meal, fluids, and protein before asking for more output."
            case "Sleep vs baseline", "Slept under 6 hours", "Slept under 7 hours", "Sleep efficiency", "Awake during sleep":
                return "Sleep is the main limiter. Aim for an easier day and make tonight's sleep window boringly protected."
            case "Illness / symptoms":
                return "Symptoms are the main limiter. Treat this as recovery-first and avoid hard training."
            case "Previous night alcohol":
                return "Last night's alcohol is still costing recovery. Hydrate, eat properly, and keep training controlled."
            default:
                break
            }
        }

        if input.illnessSeverityOutOf10 >= 7 {
            return "Illness is the main limiter today. Treat this as a recovery day, keep fluids steady, and avoid intense training."
        }

        if input.illnessSeverityOutOf10 >= 4 {
            return "Symptoms are likely dragging energy. Keep the day lighter than the score alone would suggest."
        }

        if input.illnessSeverityOutOf10 > 0 {
            return "Mild symptoms still matter. Watch for raised heart rate, low HRV, and unusually poor sleep tonight."
        }

        if input.previousNightAlcoholDrinks >= 4 {
            return "Last night's alcohol is likely the bigger recovery limiter today. Keep intensity sensible, hydrate, and protect tonight's sleep."
        }

        if input.alcoholDrinks >= 4 {
            return "You may still feel energised, but recovery risk is high. Hydrate, eat properly, and protect sleep."
        }

        if (input.hoursAwake ?? 0) >= 16 {
            return "You have been awake a long time. Keep plans realistic and protect your wind-down."
        }

        if input.alcoholDrinks > 0 {
            return "Alcohol adds recovery risk even if current energy feels good. Keep water and food steady."
        }

        if input.previousNightAlcoholDrinks > 0 {
            return "Even if you feel okay, last night's alcohol can still reduce recovery today. Keep the day steady."
        }

        if EnergyScorer.recoveryStrainAdjustment(for: input.appleWatch) < 0 {
            return "Recovery looks compromised today. Prioritise rest, hydration, and low-intensity movement."
        }

        if score < 40 {
            return "Prioritise hydration, easy movement, and a calmer day if possible."
        }

        if input.appleWatch.workoutIntensityOutOf10 ?? 0 >= 8 {
            return "You look capable, but your recent training load is high, so protect recovery."
        }

        if score < 70 {
            return "Aim for steady habits today and avoid stacking too many stressors."
        }

        return "Recovery looks solid. Keep hydration and sleep consistent."
    }

    private static func makeTrainingRecommendation(for input: EnergyInput, score: Int) -> String {
        let workoutIntensity = input.appleWatch.workoutIntensityOutOf10 ?? 0

        if input.illnessSeverityOutOf10 >= 4 {
            return "Skip hard training while symptoms are active. Choose rest, walking, or very easy movement."
        }

        if score < 40 {
            return "Avoid intense training. Choose rest, walking, stretching, or light technique work."
        }

        if workoutIntensity >= 8 {
            return "Avoid another max-effort session. Choose recovery, mobility, or low-intensity cardio."
        }

        if score < 70 {
            return "Moderate training is fine, but keep the session shorter and stop before exhaustion."
        }

        return "Training looks fine today. Push only if warm-up feels normal."
    }

    private static func makeSleepRecommendation(for input: EnergyInput) -> String {
        if EnergyScorer.sleepBaselineAdjustment(
            current: input.sleepHours,
            baseline: input.personalBaselines?.sleepHours
        ) < 0 {
            return "Sleep was down against your own baseline. Try to win back 45 to 90 minutes tonight."
        }

        if let efficiency = input.sleepQuality?.sleepEfficiency, efficiency < 0.82 {
            return "Sleep was fragmented. Keep caffeine earlier and give yourself a cleaner wind-down tonight."
        }

        if input.sleepHours < 6 {
            return "Plan an earlier night. Your score is being heavily limited by short sleep."
        }

        if input.sleepHours < 7 {
            return "Try to add 30 to 60 minutes of sleep tonight."
        }

        return "Sleep looks supportive. Keep the schedule consistent."
    }

    private static func makeCaffeineRecommendation(for input: EnergyInput) -> String {
        if input.hadCaffeineAfter6pm {
            let currentEffect = EnergyScorer.lateCaffeineCurrentEnergyAdjustment(
                hadCaffeineAfter6pm: input.hadCaffeineAfter6pm,
                hoursSinceLateCaffeine: input.hoursSinceLateCaffeine
            )

            if currentEffect > 0 {
                return "Late caffeine may be boosting current energy, but it can still raise recovery risk and disrupt sleep later."
            }

            if currentEffect < 0 {
                return "Late caffeine may now be dragging energy while still making sleep harder. Move it earlier tomorrow."
            }

            return "Late caffeine is mainly a sleep/recovery risk. Move it earlier tomorrow if you can."
        }

        if input.stressOutOf10 >= 8 {
            return "Keep caffeine modest today because stress is already high."
        }

        return "Caffeine timing looks fine. Keep it earlier in the day."
    }

    private static func makeNutritionRecommendation(for input: EnergyInput, score: Int) -> String {
        let fuelAdjustment = EnergyScorer.fuelStatusAdjustment(
            dietaryEnergyConsumed: input.dietaryEnergyConsumed,
            activeEnergyBurned: input.appleWatch.activeEnergyBurned
        )

        if input.illnessSeverityOutOf10 >= 4 {
            return "Prioritise fluids, easy meals, and enough calories while your body is fighting symptoms."
        }

        if fuelAdjustment < 0 {
            return "Logged food looks low for today's activity. Add a proper meal or snack before leaning on caffeine."
        }

        if fuelAdjustment > 0 {
            return "Fuel looks supportive for today's activity. Keep fluids and protein steady."
        }

        if input.previousNightAlcoholDrinks >= 4 {
            return "Prioritise water, electrolytes, protein, and a proper breakfast after last night's drinks."
        }

        if input.alcoholDrinks >= 4 {
            return "Prioritise water, electrolytes, and a proper meal before sleep."
        }

        if input.alcoholDrinks > 0 {
            return "Prioritise water, electrolytes, protein, and a proper breakfast."
        }

        if score < 70 {
            return "Choose balanced meals and avoid relying only on caffeine for energy."
        }

        return "Fuel normally and keep protein and fluids steady."
    }

    private static func biggestLimiter(in breakdown: [ScoreAdjustment]) -> ScoreAdjustment? {
        breakdown
            .filter { $0.points < 0 && $0.label != "Starting baseline" }
            .min { $0.points < $1.points }
    }

    private static func shouldShowNutrition(input: EnergyInput) -> Bool {
        EnergyScorer.fuelStatusAdjustment(
            dietaryEnergyConsumed: input.dietaryEnergyConsumed,
            activeEnergyBurned: input.appleWatch.activeEnergyBurned
        ) != 0
            || input.alcoholDrinks > 0
            || input.previousNightAlcoholDrinks > 0
            || input.illnessSeverityOutOf10 >= 4
    }

    private static func shouldShowTraining(input: EnergyInput, score: Int) -> Bool {
        score < 70
            || input.illnessSeverityOutOf10 >= 4
            || (input.appleWatch.workoutIntensityOutOf10 ?? 0) >= 8
    }

    private static func shouldShowSleep(input: EnergyInput) -> Bool {
        input.sleepHours < 7
            || (input.sleepQuality?.sleepEfficiency ?? 1) < 0.82
            || EnergyScorer.sleepBaselineAdjustment(
                current: input.sleepHours,
                baseline: input.personalBaselines?.sleepHours
            ) < 0
    }

    private static func shouldShowCaffeine(input: EnergyInput) -> Bool {
        input.hadCaffeineAfter6pm || input.stressOutOf10 >= 8
    }
}
