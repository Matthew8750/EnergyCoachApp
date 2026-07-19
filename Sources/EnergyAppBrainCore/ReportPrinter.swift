public struct ReportPrinter {
    public static func printReport(for input: EnergyInput) {
        let result = EnergyScorer.calculateEnergy(input: input)

        print("Energy check: \(input.dateLabel)")
        print("Sleep: \(input.sleepHours) hours")
        print("Alcohol: \(input.alcoholDrinks) drinks")
        if input.previousNightAlcoholDrinks > 0 {
            print("Previous night alcohol: \(input.previousNightAlcoholDrinks) drinks")
        }
        if let hoursAwake = input.hoursAwake {
            print("Time awake: \(TextFormatter.formatDecimal(hoursAwake)) hours")
        }
        print("Late caffeine: \(input.hadCaffeineAfter6pm ? "Yes" : "No")")
        if let hoursSinceLateCaffeine = input.hoursSinceLateCaffeine {
            print("Hours since late caffeine: \(TextFormatter.formatDecimal(hoursSinceLateCaffeine))")
        }
        print("Mood: \(input.moodOutOf10)/10")
        print("Stress: \(input.stressOutOf10)/10")
        print("Resting heart rate: \(TextFormatter.formatOptional(input.appleWatch.restingHeartRate, suffix: " bpm"))")
        print("HRV: \(TextFormatter.formatOptional(input.appleWatch.heartRateVariability, suffix: " ms"))")
        print("Steps: \(TextFormatter.formatOptional(input.appleWatch.steps, suffix: ""))")
        print("")
        print("Energy score: \(result.scoreOutOf100)/100")
        print("Predicted energy: \(result.predictedEnergyOutOf10)/10")
        print("Recovery risk: \(result.recoveryRisk.rawValue)")
        print("")
        print("Why this score:")
        for adjustment in result.breakdown {
            print("- \(adjustment.label): \(TextFormatter.formatPoints(adjustment.points))")
        }
        print("")
        print("Recommendations:")
        for recommendation in result.recommendations {
            print("- \(recommendation.category): \(recommendation.message)")
        }
    }
}
