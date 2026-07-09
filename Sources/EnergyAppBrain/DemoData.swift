struct DemoData {
    static func makeDemoScenarios() -> [EnergyInput] {
        [
            EnergyInput(
                dateLabel: "Bad sleep + alcohol",
                sleepHours: 5.5,
                alcoholDrinks: 3,
                hadCaffeineAfter6pm: true,
                moodOutOf10: 5,
                stressOutOf10: 7,
                appleWatch: AppleWatchMetrics(
                    restingHeartRate: 68,
                    heartRateVariability: 35,
                    steps: 4_200,
                    activeEnergyBurned: 310,
                    exerciseMinutes: 12,
                    workoutIntensityOutOf10: 2
                )
            ),
            EnergyInput(
                dateLabel: "Good recovery day",
                sleepHours: 8.2,
                alcoholDrinks: 0,
                hadCaffeineAfter6pm: false,
                moodOutOf10: 8,
                stressOutOf10: 3,
                appleWatch: AppleWatchMetrics(
                    restingHeartRate: 56,
                    heartRateVariability: 62,
                    steps: 8_800,
                    activeEnergyBurned: 620,
                    exerciseMinutes: 38,
                    workoutIntensityOutOf10: 4
                )
            ),
            EnergyInput(
                dateLabel: "High stress workday",
                sleepHours: 6.6,
                alcoholDrinks: 0,
                hadCaffeineAfter6pm: true,
                moodOutOf10: 4,
                stressOutOf10: 9,
                appleWatch: AppleWatchMetrics(
                    restingHeartRate: 78,
                    heartRateVariability: 28,
                    steps: 2_700,
                    activeEnergyBurned: 260,
                    exerciseMinutes: 5,
                    workoutIntensityOutOf10: 1
                )
            ),
            EnergyInput(
                dateLabel: "Hard training day",
                sleepHours: 7.4,
                alcoholDrinks: 0,
                hadCaffeineAfter6pm: false,
                moodOutOf10: 7,
                stressOutOf10: 4,
                appleWatch: AppleWatchMetrics(
                    restingHeartRate: 64,
                    heartRateVariability: 46,
                    steps: 12_500,
                    activeEnergyBurned: 940,
                    exerciseMinutes: 78,
                    workoutIntensityOutOf10: 9
                )
            )
        ]
    }
}
