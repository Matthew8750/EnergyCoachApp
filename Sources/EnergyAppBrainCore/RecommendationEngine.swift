public struct RecommendationEngine {
    public static func makeRecommendations(for input: EnergyInput, score: Int) -> [Recommendation] {
        [
            Recommendation(
                category: "Recovery",
                message: makeRecoveryRecommendation(for: input, score: score)
            ),
            Recommendation(
                category: "Training",
                message: makeTrainingRecommendation(for: input, score: score)
            ),
            Recommendation(
                category: "Sleep",
                message: makeSleepRecommendation(for: input)
            ),
            Recommendation(
                category: "Caffeine",
                message: makeCaffeineRecommendation(for: input)
            ),
            Recommendation(
                category: "Nutrition",
                message: makeNutritionRecommendation(for: input, score: score)
            )
        ]
    }

    private static func makeRecoveryRecommendation(for input: EnergyInput, score: Int) -> String {
        if EnergyScorer.recoveryStrainAdjustment(for: input.appleWatch) < 0 {
            return "Recovery looks compromised today. Prioritise rest, hydration, and low-intensity movement."
        }

        if score < 40 {
            return "Prioritise hydration, easy movement, and a calmer day if possible."
        }

        if score < 70 {
            return "Aim for steady habits today and avoid stacking too many stressors."
        }

        if input.appleWatch.workoutIntensityOutOf10 ?? 0 >= 8 {
            return "You look capable, but your recent training load is high, so protect recovery."
        }

        return "Recovery looks solid. Keep hydration and sleep consistent."
    }

    private static func makeTrainingRecommendation(for input: EnergyInput, score: Int) -> String {
        let workoutIntensity = input.appleWatch.workoutIntensityOutOf10 ?? 0

        if score < 40 {
            return "Avoid intense training. Choose rest, walking, stretching, or light technique work."
        }

        if workoutIntensity >= 8 {
            return "Avoid another max-effort session. Choose recovery, mobility, or low-intensity cardio."
        }

        if score < 70 {
            return "Moderate training is fine, but keep the session shorter and stop before exhaustion."
        }

        return "You can train normally today."
    }

    private static func makeSleepRecommendation(for input: EnergyInput) -> String {
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
            return "Move caffeine earlier tomorrow to protect sleep quality."
        }

        if input.stressOutOf10 >= 8 {
            return "Keep caffeine modest today because stress is already high."
        }

        return "Caffeine timing looks fine. Keep it earlier in the day."
    }

    private static func makeNutritionRecommendation(for input: EnergyInput, score: Int) -> String {
        if input.alcoholDrinks > 0 {
            return "Prioritise water, electrolytes, protein, and a proper breakfast."
        }

        if score < 70 {
            return "Choose balanced meals and avoid relying only on caffeine for energy."
        }

        return "Fuel normally and keep protein and fluids steady."
    }
}
