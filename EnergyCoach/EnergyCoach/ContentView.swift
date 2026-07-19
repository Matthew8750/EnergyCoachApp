//
//  ContentView.swift
//  EnergyCoach
//
//  Created by helen robinson on 11/07/2026.
//

import EnergyAppBrainCore
import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("hasLinkedHealthData") private var hasLinkedHealthData = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("manualEntryDate") private var manualEntryDate = ""
    @AppStorage("alcoholDrinks") private var alcoholDrinks = 0
    @AppStorage("previousNightAlcoholDrinks") private var previousNightAlcoholDrinks = 0
    @AppStorage("hadCaffeineAfter6pm") private var hadCaffeineAfter6pm = false
    @AppStorage("moodOutOf10") private var moodOutOf10 = 0
    @AppStorage("stressOutOf10") private var stressOutOf10 = 0
    @AppStorage("illnessSeverityOutOf10") private var illnessSeverityOutOf10 = 0
    @AppStorage("workoutIntensityOutOf10") private var workoutIntensityOutOf10 = 4
    @AppStorage("actualEnergyOutOf10") private var actualEnergyOutOf10 = 0
    @AppStorage("hasActualEnergyCheckIn") private var hasActualEnergyCheckIn = false
    @AppStorage("didDefaultMoodStressToUnknown") private var didDefaultMoodStressToUnknown = false
    @StateObject private var healthKit = HealthKitManager()
    @StateObject private var watchSync = WatchSyncManager()

    @State private var isShowingAbout = false

    @State private var sleepHours = ContentView.isScreenshotMode ? 8.2 : 7.2
    @State private var sleepQuality: SleepQualityMetrics?
    @State private var hoursAwake = ContentView.isScreenshotMode ? 6.5 : ContentView.estimatedHoursAwakeNow()
    @State private var restingHeartRate = ContentView.isScreenshotMode ? 56 : 64
    @State private var heartRateVariability = ContentView.isScreenshotMode ? 74.0 : 48.0
    @State private var respiratoryRate: Double? = ContentView.isScreenshotMode ? 14.2 : nil
    @State private var oxygenSaturation: Double? = ContentView.isScreenshotMode ? 0.98 : nil
    @State private var walkingHeartRateAverage: Int? = ContentView.isScreenshotMode ? 91 : nil
    @State private var steps = ContentView.isScreenshotMode ? 8_450 : 6_500
    @State private var activeEnergyBurned = ContentView.isScreenshotMode ? 630 : 540
    @State private var exerciseMinutes = ContentView.isScreenshotMode ? 42 : 35
    @State private var standMinutes: Int? = ContentView.isScreenshotMode ? 510 : nil
    @State private var dietaryEnergyConsumed: Int? = ContentView.isScreenshotMode ? 1_820 : nil
    @State private var bodyProfile: BodyProfile?
    @State private var personalBaselines: PersonalBaselines?
    @State private var lastWakeTime: Date?

    private var input: EnergyInput {
        EnergyInput(
            dateLabel: "Today",
            sleepHours: sleepHours,
            alcoholDrinks: alcoholDrinks,
            previousNightAlcoholDrinks: previousNightAlcoholDrinks,
            hadCaffeineAfter6pm: hadCaffeineAfter6pm,
            hoursSinceLateCaffeine: estimatedHoursSinceLateCaffeine,
            moodOutOf10: moodOutOf10,
            stressOutOf10: stressOutOf10,
            illnessSeverityOutOf10: illnessSeverityOutOf10,
            sleepQuality: sleepQuality,
            appleWatch: AppleWatchMetrics(
                restingHeartRate: restingHeartRate,
                heartRateVariability: heartRateVariability,
                respiratoryRate: respiratoryRate,
                oxygenSaturation: oxygenSaturation,
                walkingHeartRateAverage: walkingHeartRateAverage,
                steps: steps,
                activeEnergyBurned: activeEnergyBurned,
                exerciseMinutes: exerciseMinutes,
                standMinutes: standMinutes,
                workoutIntensityOutOf10: workoutIntensityOutOf10
            ),
            dietaryEnergyConsumed: dietaryEnergyConsumed,
            hoursAwake: hoursAwake,
            bodyProfile: bodyProfile,
            personalBaselines: personalBaselines
        )
    }

    private var result: EnergyResult {
        EnergyScorer.calculateEnergy(input: input)
    }

    private var watchSyncSignature: String {
        var parts: [String] = []
        parts.append(String(result.scoreOutOf100))
        parts.append(result.recoveryRisk.rawValue)
        parts.append(result.recommendations.first?.message ?? result.recoveryRisk.summary)
        parts.append(String(format: "%.1f", sleepHours))
        parts.append(String(format: "%.1f", hoursAwake))
        parts.append(String(alcoholDrinks))
        parts.append(String(previousNightAlcoholDrinks))
        parts.append(String(hadCaffeineAfter6pm))
        parts.append(String(moodOutOf10))
        parts.append(String(stressOutOf10))
        parts.append(String(illnessSeverityOutOf10))
        parts.append(String(restingHeartRate))
        parts.append(String(format: "%.0f", heartRateVariability))
        parts.append(respiratoryRate.map { String(format: "%.1f", $0) } ?? "unknown")
        parts.append(oxygenSaturation.map { String(format: "%.2f", $0) } ?? "unknown")
        parts.append(walkingHeartRateAverage.map(String.init) ?? "unknown")
        parts.append(String(steps))
        parts.append(String(activeEnergyBurned))
        parts.append(String(exerciseMinutes))
        parts.append(standMinutes.map(String.init) ?? "unknown")
        parts.append(dietaryEnergyConsumed.map(String.init) ?? "unknown")
        parts.append(String(workoutIntensityOutOf10))
        parts.append(sleepQuality?.deepSleepHours.map { String(format: "%.1f", $0) } ?? "unknown")
        parts.append(sleepQuality?.remSleepHours.map { String(format: "%.1f", $0) } ?? "unknown")
        parts.append(sleepQuality?.sleepEfficiency.map { String(format: "%.2f", $0) } ?? "unknown")
        parts.append(bodyProfile?.biologicalSex?.rawValue ?? "unknown")
        parts.append(bodyProfile?.age.map(String.init) ?? "unknown")
        parts.append(bodyProfile?.heightCentimeters.map { String(format: "%.0f", $0) } ?? "unknown")
        parts.append(bodyProfile?.weightKilograms.map { String(format: "%.0f", $0) } ?? "unknown")
        parts.append(personalBaselines?.sleepHours.map { String(format: "%.1f", $0) } ?? "unknown")
        parts.append(personalBaselines?.restingHeartRate.map(String.init) ?? "unknown")
        parts.append(personalBaselines?.heartRateVariability.map { String(format: "%.0f", $0) } ?? "unknown")
        return parts.joined(separator: "|")
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                    ScoreHeader(result: result).id("dashboard")
                    RecommendationsSection(recommendations: result.recommendations).id("recommendations")
                    DailyCheckInSection(
                        predictedEnergyOutOf10: result.predictedEnergyOutOf10,
                        actualEnergyOutOf10: $actualEnergyOutOf10,
                        hasActualEnergyCheckIn: $hasActualEnergyCheckIn
                    )
                    HealthDataSection(
                        state: Self.isScreenshotMode ? .idle : healthKit.state,
                        isHealthDataAvailable: Self.isScreenshotMode || healthKit.isHealthDataAvailable,
                        hasLinkedHealthData: hasLinkedHealthData,
                        loadHealthData: loadHealthData
                    ).id("health")
                    SignalSummarySection(
                        sleepHours: sleepHours,
                        hoursAwake: hoursAwake,
                        heartRateVariability: heartRateVariability,
                        restingHeartRate: restingHeartRate,
                        activeEnergyBurned: activeEnergyBurned,
                        dietaryEnergyConsumed: dietaryEnergyConsumed
                    ).id("signals")
                    BodyProfileSection(profile: bodyProfile)
                    WatchMetricsSection(
                        sleepQuality: sleepQuality,
                        respiratoryRate: respiratoryRate,
                        oxygenSaturation: oxygenSaturation,
                        walkingHeartRateAverage: walkingHeartRateAverage,
                        standMinutes: standMinutes,
                        dietaryEnergyConsumed: dietaryEnergyConsumed
                    )
                    BaselineSection(baselines: personalBaselines)
                    BreakdownSection(adjustments: result.breakdown).id("breakdown")
                    InputSection(
                        sleepHours: $sleepHours,
                        hoursAwake: $hoursAwake,
                        alcoholDrinks: $alcoholDrinks,
                        hadCaffeineAfter6pm: $hadCaffeineAfter6pm,
                        moodOutOf10: $moodOutOf10,
                        stressOutOf10: $stressOutOf10,
                        illnessSeverityOutOf10: $illnessSeverityOutOf10,
                        restingHeartRate: $restingHeartRate,
                        heartRateVariability: $heartRateVariability,
                        steps: $steps,
                        activeEnergyBurned: $activeEnergyBurned,
                        exerciseMinutes: $exerciseMinutes,
                        workoutIntensityOutOf10: $workoutIntensityOutOf10
                    )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                }
                .onAppear {
                    guard let target = Self.screenshotSection else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Energy Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAbout = true
                    } label: {
                        Label("About Energy Coach", systemImage: "info.circle")
                    }
                }
            }
            .sheet(isPresented: $isShowingAbout) {
                AboutAndPrivacyView()
            }
        }
        .task {
            if Self.isScreenshotMode {
                applyScreenshotData()
            } else {
                defaultMoodStressToUnknownIfNeeded()
                resetDailyManualInputsIfNeeded()
                updateHoursAwakeFromWakeTime()
            }
            syncWatch()

            if hasLinkedHealthData && !Self.isScreenshotMode {
                loadHealthData()
            }
        }
        .task {
            await runTimeAwakeTicker()
        }
        .task {
            await runHealthDataTicker()
        }
        .onAppear {
            syncWatch()
        }
        .onChange(of: watchSyncSignature) { _, _ in
            syncWatch()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                if hasLinkedHealthData {
                    loadHealthData()
                }
                syncWatch()
            }
        }
        .fullScreenCover(isPresented: onboardingPresentation) {
            OnboardingView {
                hasCompletedOnboarding = true
            }
        }
    }

    private var onboardingPresentation: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { isPresented in
                if !isPresented {
                    hasCompletedOnboarding = true
                }
            }
        )
    }

    private static var isScreenshotMode: Bool {
        ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
    }

    private static var screenshotSection: String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-ScreenshotSection"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    private func applyScreenshotData() {
        hasCompletedOnboarding = true
        hasLinkedHealthData = true
        alcoholDrinks = 0
        previousNightAlcoholDrinks = 0
        hadCaffeineAfter6pm = false
        moodOutOf10 = 8
        stressOutOf10 = 3
        illnessSeverityOutOf10 = 0
        workoutIntensityOutOf10 = 6
        sleepQuality = SleepQualityMetrics(
            deepSleepHours: 1.6,
            remSleepHours: 1.9,
            coreSleepHours: 4.5,
            awakeDuringSleepHours: 0.2,
            sleepEfficiency: 0.96
        )
        bodyProfile = BodyProfile(age: 22, biologicalSex: .male, heightCentimeters: 180, weightKilograms: 76)
        personalBaselines = PersonalBaselines(
            sleepHours: 7.5,
            restingHeartRate: 60,
            heartRateVariability: 61,
            activeEnergyBurned: 560
        )
    }

    private func loadHealthData() {
        Task {
            guard let snapshot = await healthKit.requestAndLoadToday() else {
                return
            }

            hasLinkedHealthData = true
            apply(snapshot)
            syncWatch()
        }
    }

    private func syncWatch() {
        watchSync.update(
            score: result.scoreOutOf100,
            recoveryRisk: result.recoveryRisk.rawValue,
            message: result.recommendations.first?.message ?? result.recoveryRisk.summary
        )
    }

    private func apply(_ snapshot: HealthSnapshot) {
        bodyProfile = snapshot.bodyProfile
        sleepQuality = snapshot.sleepQuality
        personalBaselines = snapshot.personalBaselines
        lastWakeTime = snapshot.lastWakeTime

        if let sleepHours = snapshot.sleepHours {
            self.sleepHours = rounded(sleepHours, places: 1)
        }

        if snapshot.lastWakeTime != nil {
            updateHoursAwakeFromWakeTime()
        } else if let hoursAwake = snapshot.hoursAwake {
            self.hoursAwake = rounded(hoursAwake, places: 1)
        }

        if let restingHeartRate = snapshot.restingHeartRate {
            self.restingHeartRate = restingHeartRate
        }

        if let heartRateVariability = snapshot.heartRateVariability {
            self.heartRateVariability = rounded(heartRateVariability, places: 0)
        }

        if let respiratoryRate = snapshot.respiratoryRate {
            self.respiratoryRate = rounded(respiratoryRate, places: 1)
        }

        if let oxygenSaturation = snapshot.oxygenSaturation {
            self.oxygenSaturation = rounded(oxygenSaturation, places: 2)
        }

        if let walkingHeartRateAverage = snapshot.walkingHeartRateAverage {
            self.walkingHeartRateAverage = walkingHeartRateAverage
        }

        if let steps = snapshot.steps {
            self.steps = steps
        }

        if let activeEnergyBurned = snapshot.activeEnergyBurned {
            self.activeEnergyBurned = activeEnergyBurned
        }

        if let exerciseMinutes = snapshot.exerciseMinutes {
            self.exerciseMinutes = exerciseMinutes
        }

        if let standMinutes = snapshot.standMinutes {
            self.standMinutes = standMinutes
        }

        if let dietaryEnergyConsumed = snapshot.dietaryEnergyConsumed {
            self.dietaryEnergyConsumed = dietaryEnergyConsumed
        }
    }

    private func rounded(_ value: Double, places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (value * multiplier).rounded() / multiplier
    }

    private func resetDailyManualInputsIfNeeded() {
        let currentEnergyDay = Self.energyDayKey()
        guard manualEntryDate != currentEnergyDay else {
            return
        }

        manualEntryDate = currentEnergyDay
        previousNightAlcoholDrinks = alcoholDrinks
        alcoholDrinks = 0
        actualEnergyOutOf10 = 0
        hasActualEnergyCheckIn = false
        hadCaffeineAfter6pm = false
        moodOutOf10 = 0
        stressOutOf10 = 0
        illnessSeverityOutOf10 = 0
        workoutIntensityOutOf10 = 4
        sleepQuality = nil
        respiratoryRate = nil
        oxygenSaturation = nil
        walkingHeartRateAverage = nil
        standMinutes = nil
        dietaryEnergyConsumed = nil
        lastWakeTime = nil
        hoursAwake = Self.estimatedHoursAwakeNow()
    }

    private func defaultMoodStressToUnknownIfNeeded() {
        guard !didDefaultMoodStressToUnknown else {
            return
        }

        moodOutOf10 = 0
        stressOutOf10 = 0
        didDefaultMoodStressToUnknown = true
    }

    private func runTimeAwakeTicker() async {
        guard !Self.isScreenshotMode else { return }
        while !Task.isCancelled {
            updateHoursAwakeFromWakeTime()
            syncWatch()
            try? await Task.sleep(for: .seconds(60))
        }
    }

    private func runHealthDataTicker() async {
        guard !Self.isScreenshotMode else { return }
        while !Task.isCancelled {
            if hasLinkedHealthData {
                loadHealthData()
            }

            try? await Task.sleep(for: .seconds(300))
        }
    }

    private func updateHoursAwakeFromWakeTime() {
        let wakeTime = lastWakeTime ?? Self.assumedWakeTimeForCurrentDay()
        let hours = Date().timeIntervalSince(wakeTime) / 3_600
        hoursAwake = rounded(min(24, max(0, hours)), places: 1)
    }

    private static func estimatedHoursAwakeNow() -> Double {
        let hours = Date().timeIntervalSince(assumedWakeTimeForCurrentDay()) / 3_600
        return min(24, max(0, (hours * 10).rounded() / 10))
    }

    private static func assumedWakeTimeForCurrentDay() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let todayWakeTime = calendar.date(byAdding: .minute, value: 7 * 60 + 30, to: startOfDay) ?? startOfDay

        if todayWakeTime <= now {
            return todayWakeTime
        }

        let yesterday = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        return calendar.date(byAdding: .minute, value: 7 * 60 + 30, to: yesterday) ?? yesterday
    }

    private static func energyDayKey() -> String {
        let calendar = Calendar.current
        let now = Date()
        let energyDay = calendar.date(byAdding: .hour, value: -7, to: now) ?? now
        let components = calendar.dateComponents([.year, .month, .day], from: energyDay)
        return "\(components.year ?? 0)-\(components.month ?? 0)-\(components.day ?? 0)"
    }

    private var estimatedHoursSinceLateCaffeine: Double? {
        guard hadCaffeineAfter6pm else {
            return nil
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        guard let sixPM = calendar.date(byAdding: .hour, value: 18, to: startOfDay) else {
            return nil
        }

        let hours = max(0, now.timeIntervalSince(sixPM) / 3_600)
        return rounded(hours, places: 1)
    }
}

private struct OnboardingView: View {
    let complete: () -> Void

    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                OnboardingPage(
                    systemImage: "bolt.heart.fill",
                    title: "Understand Your Energy",
                    message: "Turn sleep, recovery, activity, and optional daily check-ins into one clear wellness estimate.",
                    tint: .teal
                )
                .tag(0)

                OnboardingPage(
                    systemImage: "heart.text.square.fill",
                    title: "You Control Health Access",
                    message: "Choose which Apple Health categories Energy Coach may read. The app never writes to Apple Health.",
                    tint: .red
                )
                .tag(1)

                OnboardingPage(
                    systemImage: "checkmark.shield.fill",
                    title: "Private by Design",
                    message: "Your wellness data and check-ins stay on this device. Energy Coach provides general guidance, not medical advice.",
                    tint: .green
                )
                .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(action: advance) {
                Text(page == 2 ? "Get Started" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
    }

    private func advance() {
        if page < 2 {
            withAnimation {
                page += 1
            }
        } else {
            complete()
        }
    }
}

private struct OnboardingPage: View {
    let systemImage: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: systemImage)
                .font(.system(size: 72, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
        .padding(28)
    }
}

private struct AboutAndPrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("About") {
                    Text("Energy Coach turns your Apple Health signals and optional check-ins into a daily wellness estimate and practical recovery suggestions.")
                }

                Section("Your health data") {
                    Label("Health data is read only after you grant permission.", systemImage: "checkmark.shield")
                    Label("Energy Coach does not write to Apple Health.", systemImage: "heart.text.square")
                    Label("Your check-ins and preferences stay on this device.", systemImage: "iphone")
                    Text("You can review or revoke Health access at any time in the Health app or iPhone Settings.")
                        .foregroundStyle(.secondary)
                }

                Section("Wellness, not medical advice") {
                    Text("Scores and suggestions are general wellness information. They are not a diagnosis, treatment, or substitute for advice from a qualified healthcare professional.")
                    Text("If you feel unwell or are concerned about your health, seek appropriate medical advice rather than relying on the app.")
                        .foregroundStyle(.secondary)
                }

                Section("How estimates work") {
                    Text("The estimate uses rules based on signals such as sleep, time awake, activity, recovery measurements, and optional lifestyle check-ins. It may be incomplete or inaccurate when data is missing.")
                }
            }
            .navigationTitle("About & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HealthDataSection: View {
    let state: HealthKitManager.LoadState
    let isHealthDataAvailable: Bool
    let hasLinkedHealthData: Bool
    let loadHealthData: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(.teal)
                    .frame(width: 36, height: 36)
                    .background(Color.teal.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Watch Data")
                        .font(.headline)
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Button(action: loadHealthData) {
                Label(buttonTitle, systemImage: buttonIcon)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isHealthDataAvailable || state == .loading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusText: String {
        if !isHealthDataAvailable {
            return "Open this on your iPhone to connect Apple Health."
        }

        switch state {
        case .idle:
            if hasLinkedHealthData {
                return "Health is linked. The app updates automatically when you open it."
            }

            return "Connect Apple Health once to pull sleep stages, heart signals, calories eaten, activity, and personal baselines."
        case .loading:
            return "Requesting Health access and reading today’s metrics."
        case .loaded(let message):
            return message
        case .failed(let message):
            return message
        }
    }

    private var buttonTitle: String {
        state == .loading ? "Reading Health Data" : "Update From Health"
    }

    private var buttonIcon: String {
        state == .loading ? "hourglass" : "heart.text.square"
    }
}

private struct ScoreHeader: View {
    let result: EnergyResult

    private var tint: Color {
        if result.scoreOutOf100 < 40 {
            return .red
        }

        if result.scoreOutOf100 < 70 {
            return .orange
        }

        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(energyLabel)
                        .font(.title2.weight(.bold))
                }

                Spacer()

                Image(systemName: "bolt.heart.fill")
                    .font(.title2)
                    .foregroundStyle(tint)
                    .frame(width: 44, height: 44)
                    .background(tint.opacity(0.14), in: Circle())
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(result.scoreOutOf100)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text("/100")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: Double(result.scoreOutOf100), total: 100)
                    .tint(tint)
                Text("Predicted energy: \(result.predictedEnergyOutOf10)/10")
                    .font(.headline)
            }

            HStack {
                Label("Recovery risk", systemImage: "moon.zzz")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(result.recoveryRisk.rawValue)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(recoveryRiskTint)
            }
            .padding(12)
            .background(recoveryRiskTint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var recoveryRiskTint: Color {
        switch result.recoveryRisk {
        case .low:
            return .green
        case .moderate:
            return .orange
        case .high:
            return .red
        }
    }

    private var energyLabel: String {
        if result.scoreOutOf100 < 40 {
            return "Protect recovery"
        }

        if result.scoreOutOf100 < 70 {
            return "Steady day"
        }

        return "Ready to push"
    }
}

private struct RecommendationHighlight: View {
    let recommendation: Recommendation?

    var body: some View {
        if let recommendation {
            VStack(alignment: .leading, spacing: 10) {
                Label(recommendation.category, systemImage: "sparkles")
                    .font(.headline)
                Text(recommendation.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.teal.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct DailyCheckInSection: View {
    let predictedEnergyOutOf10: Int
    @Binding var actualEnergyOutOf10: Int
    @Binding var hasActualEnergyCheckIn: Bool

    @State private var draftActualEnergy = 7.0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(title: "Daily Check-In", systemImage: "checkmark.circle")

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Predicted")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(predictedEnergyOutOf10)/10")
                        .font(.title3.weight(.bold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Actual")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(actualEnergyText)
                        .font(.title3.weight(.bold))
                }
            }

            Slider(
                value: $draftActualEnergy,
                in: 1...10,
                step: 1
            )
            .onAppear {
                draftActualEnergy = Double(hasActualEnergyCheckIn ? actualEnergyOutOf10 : predictedEnergyOutOf10)
            }
            .onChange(of: predictedEnergyOutOf10) { _, newValue in
                if !hasActualEnergyCheckIn {
                    draftActualEnergy = Double(newValue)
                }
            }

            HStack {
                Text("Felt like \(Int(draftActualEnergy))/10")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: saveCheckIn) {
                    Label(hasActualEnergyCheckIn ? "Update" : "Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }

            if hasActualEnergyCheckIn {
                Text(comparisonText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private var actualEnergyText: String {
        hasActualEnergyCheckIn ? "\(actualEnergyOutOf10)/10" : "Not saved"
    }

    private var comparisonText: String {
        let difference = actualEnergyOutOf10 - predictedEnergyOutOf10

        if difference >= 2 {
            return "The model undershot you by \(difference). This is useful training data."
        }

        if difference <= -2 {
            return "The model overshot you by \(abs(difference)). This is useful training data."
        }

        if difference == 0 {
            return "Prediction matched how you felt today."
        }

        return "Prediction was close today."
    }

    private func saveCheckIn() {
        actualEnergyOutOf10 = Int(draftActualEnergy)
        hasActualEnergyCheckIn = true
    }
}

private struct BodyProfileSection: View {
    let profile: BodyProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Profile Calibration", systemImage: "person.text.rectangle")

            if let profile {
                VStack(spacing: 10) {
                    MetricRow(title: "Age", value: formattedAge(profile.age))
                    MetricRow(title: "Sex", value: profile.biologicalSex?.rawValue ?? "Not available")
                    MetricRow(title: "Height", value: formattedCentimeters(profile.heightCentimeters))
                    MetricRow(title: "Weight", value: formattedKilograms(profile.weightKilograms))
                    MetricRow(title: "BMI", value: formattedDecimal(profile.bodyMassIndex, places: 1))
                    MetricRow(title: "Estimated BMR", value: formattedCalories(profile.estimatedBasalMetabolicRate))
                    MetricRow(title: "Estimated max HR", value: formattedHeartRate(profile.estimatedMaxHeartRate))
                }
            } else {
                Text("Connect Apple Health to calibrate activity and heart metrics with your profile.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func formattedAge(_ age: Int?) -> String {
        guard let age else {
            return "Not available"
        }

        return "\(age)"
    }

    private func formattedCentimeters(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(Int(value.rounded())) cm"
    }

    private func formattedKilograms(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return String(format: "%.1f kg", value)
    }

    private func formattedCalories(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(Int(value.rounded())) kcal/day"
    }

    private func formattedHeartRate(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) bpm"
    }

    private func formattedDecimal(_ value: Double?, places: Int) -> String {
        guard let value else {
            return "Not available"
        }

        return String(format: "%.\(places)f", value)
    }
}

private struct WatchMetricsSection: View {
    let sleepQuality: SleepQualityMetrics?
    let respiratoryRate: Double?
    let oxygenSaturation: Double?
    let walkingHeartRateAverage: Int?
    let standMinutes: Int?
    let dietaryEnergyConsumed: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Watch Signals", systemImage: "waveform.path.ecg")

            VStack(spacing: 10) {
                MetricRow(title: "Deep sleep", value: formattedHours(sleepQuality?.deepSleepHours))
                MetricRow(title: "REM sleep", value: formattedHours(sleepQuality?.remSleepHours))
                MetricRow(title: "Core sleep", value: formattedHours(sleepQuality?.coreSleepHours))
                MetricRow(title: "Awake in bed", value: formattedHours(sleepQuality?.awakeDuringSleepHours))
                MetricRow(title: "Sleep efficiency", value: formattedPercent(sleepQuality?.sleepEfficiency))
                MetricRow(title: "Respiratory rate", value: formattedRate(respiratoryRate))
                MetricRow(title: "Blood oxygen", value: formattedPercent(oxygenSaturation))
                MetricRow(title: "Walking HR", value: formattedHeartRate(walkingHeartRateAverage))
                MetricRow(title: "Stand time", value: formattedMinutes(standMinutes))
                MetricRow(title: "Food energy", value: formattedCalories(dietaryEnergyConsumed))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func formattedHours(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return String(format: "%.1fh", value)
    }

    private func formattedPercent(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(Int((value * 100).rounded()))%"
    }

    private func formattedRate(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return String(format: "%.1f/min", value)
    }

    private func formattedHeartRate(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) bpm"
    }

    private func formattedMinutes(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) min"
    }

    private func formattedCalories(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) kcal"
    }
}

private struct SignalSummarySection: View {
    let sleepHours: Double
    let hoursAwake: Double
    let heartRateVariability: Double
    let restingHeartRate: Int
    let activeEnergyBurned: Int
    let dietaryEnergyConsumed: Int?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Today’s Signals", systemImage: "gauge.with.dots.needle.bottom.50percent")

            LazyVGrid(columns: columns, spacing: 10) {
                SignalTile(title: "Sleep", value: String(format: "%.1fh", sleepHours), systemImage: "bed.double")
                SignalTile(title: "Awake", value: String(format: "%.1fh", hoursAwake), systemImage: "sun.max")
                SignalTile(title: "HRV", value: "\(Int(heartRateVariability.rounded())) ms", systemImage: "waveform.path.ecg")
                SignalTile(title: "Resting HR", value: "\(restingHeartRate) bpm", systemImage: "heart")
                SignalTile(title: "Active", value: "\(activeEnergyBurned) kcal", systemImage: "flame")
                SignalTile(title: "Food", value: dietaryEnergyConsumed.map { "\($0) kcal" } ?? "No log", systemImage: "fork.knife")
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SignalTile: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.teal)
                .frame(width: 28, height: 28)
                .background(Color.teal.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct BaselineSection: View {
    let baselines: PersonalBaselines?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Personal Baselines", systemImage: "chart.line.uptrend.xyaxis")

            VStack(spacing: 10) {
                MetricRow(title: "30-day sleep", value: formattedHours(baselines?.sleepHours))
                MetricRow(title: "30-day resting HR", value: formattedHeartRate(baselines?.restingHeartRate))
                MetricRow(title: "30-day HRV", value: formattedMilliseconds(baselines?.heartRateVariability))
                MetricRow(title: "30-day active energy", value: formattedCalories(baselines?.activeEnergyBurned))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func formattedHours(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return String(format: "%.1fh", value)
    }

    private func formattedHeartRate(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) bpm"
    }

    private func formattedMilliseconds(_ value: Double?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(Int(value.rounded())) ms"
    }

    private func formattedCalories(_ value: Int?) -> String {
        guard let value else {
            return "Not available"
        }

        return "\(value) kcal/day"
    }
}

private struct BreakdownSection: View {
    let adjustments: [ScoreAdjustment]

    private var visibleAdjustments: [ScoreAdjustment] {
        Array(
            adjustments
                .filter { $0.label == "Starting baseline" || abs($0.points) >= 5 }
                .prefix(8)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Why", systemImage: "list.bullet.clipboard")

            ForEach(Array(visibleAdjustments.enumerated()), id: \.offset) { _, adjustment in
                HStack(spacing: 12) {
                    Text(adjustment.label)
                        .font(.subheadline)
                    Spacer()
                    Text(pointsText(for: adjustment.points))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(adjustment.points < 0 ? .red : .green)
                }
                .padding(.vertical, 2)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func pointsText(for points: Int) -> String {
        points > 0 ? "+\(points)" : "\(points)"
    }
}

private struct MetricRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct InputSection: View {
    @Binding var sleepHours: Double
    @Binding var hoursAwake: Double
    @Binding var alcoholDrinks: Int
    @Binding var hadCaffeineAfter6pm: Bool
    @Binding var moodOutOf10: Int
    @Binding var stressOutOf10: Int
    @Binding var illnessSeverityOutOf10: Int
    @Binding var restingHeartRate: Int
    @Binding var heartRateVariability: Double
    @Binding var steps: Int
    @Binding var activeEnergyBurned: Int
    @Binding var exerciseMinutes: Int
    @Binding var workoutIntensityOutOf10: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle(title: "Inputs", systemImage: "slider.horizontal.3")

            SliderRow(
                title: "Sleep",
                value: $sleepHours,
                range: 0...12,
                step: 0.25,
                displayValue: String(format: "%.1fh", sleepHours)
            )

            SliderRow(
                title: "Time awake",
                value: $hoursAwake,
                range: 0...24,
                step: 0.25,
                displayValue: String(format: "%.1fh", hoursAwake)
            )

            StepperRow(title: "Alcohol", value: $alcoholDrinks, range: 0...8, suffix: "drinks")

            Toggle(isOn: $hadCaffeineAfter6pm) {
                Label("Caffeine after 6pm", systemImage: "cup.and.saucer")
            }

            StepperRow(title: "Mood", value: $moodOutOf10, range: 0...10, suffix: "/10")
            StepperRow(title: "Stress", value: $stressOutOf10, range: 0...10, suffix: "/10")
            StepperRow(title: "Illness / symptoms", value: $illnessSeverityOutOf10, range: 0...10, suffix: "/10")
            StepperRow(title: "Resting heart rate", value: $restingHeartRate, range: 40...110, suffix: "bpm")

            SliderRow(
                title: "HRV",
                value: $heartRateVariability,
                range: 10...100,
                step: 1,
                displayValue: "\(Int(heartRateVariability)) ms"
            )

            StepperRow(title: "Steps", value: $steps, range: 0...30_000, step: 500, suffix: "steps")
            StepperRow(title: "Active energy", value: $activeEnergyBurned, range: 0...1_800, step: 25, suffix: "kcal")
            StepperRow(title: "Exercise", value: $exerciseMinutes, range: 0...180, step: 5, suffix: "min")
            StepperRow(title: "Workout intensity", value: $workoutIntensityOutOf10, range: 0...10, suffix: "/10")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct RecommendationsSection: View {
    let recommendations: [Recommendation]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: "Next Steps", systemImage: "checklist")

            VStack(spacing: 10) {
                ForEach(Array(recommendations.prefix(3).enumerated()), id: \.offset) { index, recommendation in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(Color.teal, in: Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text(recommendation.category)
                                .font(.subheadline.weight(.bold))
                            Text(recommendation.message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

private struct StepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let suffix: String

    init(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int = 1,
        suffix: String
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.suffix = suffix
    }

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value) \(suffix)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
