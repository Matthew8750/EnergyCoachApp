import Foundation

public struct ManualEntryResult {
    public let input: EnergyInput
    public let log: DailyEnergyLog
}

public struct ManualEntry {
    public static func collectDailyLog() -> ManualEntryResult {
        print("")
        print("Manual daily log")
        print("Press Enter to use the default shown in brackets.")
        print("")

        let dateLabel = promptString("Day name or date", defaultValue: todayDateLabel())
        let sleepHours = promptDouble("Sleep hours", defaultValue: 7.0)
        let hoursAwake = promptOptionalDouble("Hours awake")
        let alcoholDrinks = promptInt("Alcohol drinks", defaultValue: 0)
        let previousNightAlcoholDrinks = promptInt("Previous night alcohol drinks", defaultValue: 0)
        let hadCaffeineAfter6pm = promptBool("Caffeine after 6pm", defaultValue: false)
        let hoursSinceLateCaffeine = hadCaffeineAfter6pm ? promptOptionalDouble("Hours since late caffeine") : nil
        let moodOutOf10 = promptIntInRange("Mood 1-10", defaultValue: 6, range: 1...10)
        let stressOutOf10 = promptIntInRange("Stress 1-10", defaultValue: 5, range: 1...10)
        let restingHeartRate = promptOptionalInt("Resting heart rate bpm")
        let heartRateVariability = promptOptionalDouble("HRV ms")
        let steps = promptOptionalInt("Steps")
        let activeEnergyBurned = promptOptionalInt("Active energy burned")
        let exerciseMinutes = promptOptionalInt("Exercise minutes")
        let workoutIntensity = promptOptionalIntInRange("Workout intensity 1-10", range: 1...10)
        let actualEnergy = promptOptionalIntInRange("Actual energy 1-10", range: 1...10)

        let input = EnergyInput(
            dateLabel: dateLabel,
            sleepHours: sleepHours,
            alcoholDrinks: alcoholDrinks,
            previousNightAlcoholDrinks: previousNightAlcoholDrinks,
            hadCaffeineAfter6pm: hadCaffeineAfter6pm,
            hoursSinceLateCaffeine: hoursSinceLateCaffeine,
            moodOutOf10: moodOutOf10,
            stressOutOf10: stressOutOf10,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: restingHeartRate,
                heartRateVariability: heartRateVariability,
                steps: steps,
                activeEnergyBurned: activeEnergyBurned,
                exerciseMinutes: exerciseMinutes,
                workoutIntensityOutOf10: workoutIntensity
            ),
            hoursAwake: hoursAwake
        )
        let result = EnergyScorer.calculateEnergy(input: input)
        let log = DailyEnergyLog(
            dateLabel: dateLabel,
            input: input,
            result: result,
            actualEnergyOutOf10: actualEnergy
        )

        return ManualEntryResult(input: input, log: log)
    }

    public static func promptString(_ label: String, defaultValue: String) -> String {
        print("\(label) [\(defaultValue)]: ", terminator: "")
        let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? defaultValue : value
    }

    private static func promptDouble(_ label: String, defaultValue: Double) -> Double {
        while true {
            print("\(label) [\(defaultValue)]: ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if value.isEmpty {
                return defaultValue
            }

            if let number = Double(value) {
                return number
            }

            print("Please enter a number.")
        }
    }

    private static func promptInt(_ label: String, defaultValue: Int) -> Int {
        while true {
            print("\(label) [\(defaultValue)]: ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if value.isEmpty {
                return defaultValue
            }

            if let number = Int(value) {
                return number
            }

            print("Please enter a whole number.")
        }
    }

    private static func promptIntInRange(_ label: String, defaultValue: Int, range: ClosedRange<Int>) -> Int {
        while true {
            let number = promptInt(label, defaultValue: defaultValue)

            if range.contains(number) {
                return number
            }

            print("Please enter a number from \(range.lowerBound) to \(range.upperBound).")
        }
    }

    private static func promptBool(_ label: String, defaultValue: Bool) -> Bool {
        let defaultText = defaultValue ? "y" : "n"

        while true {
            print("\(label) y/n [\(defaultText)]: ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

            if value.isEmpty {
                return defaultValue
            }

            if ["y", "yes", "true"].contains(value) {
                return true
            }

            if ["n", "no", "false"].contains(value) {
                return false
            }

            print("Please enter y or n.")
        }
    }

    private static func promptOptionalInt(_ label: String) -> Int? {
        while true {
            print("\(label) [blank if unavailable]: ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if value.isEmpty {
                return nil
            }

            if let number = Int(value) {
                return number
            }

            print("Please enter a whole number or leave blank.")
        }
    }

    private static func promptOptionalDouble(_ label: String) -> Double? {
        while true {
            print("\(label) [blank if unavailable]: ", terminator: "")
            let value = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if value.isEmpty {
                return nil
            }

            if let number = Double(value) {
                return number
            }

            print("Please enter a number or leave blank.")
        }
    }

    private static func promptOptionalIntInRange(_ label: String, range: ClosedRange<Int>) -> Int? {
        while true {
            guard let number = promptOptionalInt(label) else {
                return nil
            }

            if range.contains(number) {
                return number
            }

            print("Please enter a number from \(range.lowerBound) to \(range.upperBound), or leave blank.")
        }
    }

    private static func todayDateLabel() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
