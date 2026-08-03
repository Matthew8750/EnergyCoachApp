import Charts
import StoreKit
import SwiftUI

struct HistoryView: View {
    private enum HistoryRange: String, CaseIterable, Identifiable {
        case week = "7 Days"
        case month = "30 Days"
        case all = "All"

        var id: Self { self }
    }

    @ObservedObject var historyStore: HistoryStore
    @ObservedObject var subscriptionManager: SubscriptionManager

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingPaywall = false
    @State private var selectedRange: HistoryRange = .week
    @StateObject private var reminderManager = DailyReminderManager()

    private var entries: [EnergyHistoryEntry] {
        let available = historyStore.visibleEntries(isPro: subscriptionManager.isPro)
        guard subscriptionManager.isPro else { return available }

        let days: Int?
        switch selectedRange {
        case .week: days = 7
        case .month: days = 30
        case .all: days = nil
        }

        guard let days,
              let cutoff = Calendar.current.date(byAdding: .day, value: -(days - 1), to: Calendar.current.startOfDay(for: .now)) else {
            return available
        }
        return available.filter { $0.date >= cutoff }
    }

    private var allEntries: [EnergyHistoryEntry] { historyStore.entries }

    private var averageScore: Int {
        guard !entries.isEmpty else { return 0 }
        return Int((Double(entries.map(\.scoreOutOf100).reduce(0, +)) / Double(entries.count)).rounded())
    }

    private var averageSleep: Double {
        guard !entries.isEmpty else { return 0 }
        return entries.map(\.sleepHours).reduce(0, +) / Double(entries.count)
    }

    private var averageHRV: Int {
        guard !entries.isEmpty else { return 0 }
        return Int((entries.map(\.heartRateVariability).reduce(0, +) / Double(entries.count)).rounded())
    }

    private var averageRestingHeartRate: Int {
        guard !entries.isEmpty else { return 0 }
        return Int((Double(entries.map(\.restingHeartRate).reduce(0, +)) / Double(entries.count)).rounded())
    }

    private var bestDay: EnergyHistoryEntry? { entries.max { $0.scoreOutOf100 < $1.scoreOutOf100 } }
    private var lowestDay: EnergyHistoryEntry? { entries.min { $0.scoreOutOf100 < $1.scoreOutOf100 } }

    private var trendChange: Int {
        guard entries.count >= 2 else { return 0 }
        let midpoint = entries.count / 2
        let earlier = entries.prefix(midpoint)
        let later = entries.suffix(entries.count - midpoint)
        guard !earlier.isEmpty, !later.isEmpty else { return 0 }
        let earlierAverage = Double(earlier.map(\.scoreOutOf100).reduce(0, +)) / Double(earlier.count)
        let laterAverage = Double(later.map(\.scoreOutOf100).reduce(0, +)) / Double(later.count)
        return Int((laterAverage - earlierAverage).rounded())
    }

    private var checkInStreak: Int {
        let calendar = Calendar.current
        let checkedDays = Set(allEntries.compactMap { entry in
            entry.actualEnergyOutOf10 == nil ? nil : calendar.startOfDay(for: entry.date)
        })
        guard !checkedDays.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: .now)
        if !checkedDays.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }

        var streak = 0
        while checkedDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    if !subscriptionManager.isPro {
                        proBanner
                    } else {
                        Picker("History range", selection: $selectedRange) {
                            ForEach(HistoryRange.allCases) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if entries.isEmpty {
                        ContentUnavailableView(
                            "History starts today",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("Open Energy Coach each day to build your energy history.")
                        )
                        .padding(.top, 80)
                    } else {
                        streakCard
                        if subscriptionManager.isPro {
                            insightsDashboard
                        }
                        scoreChart
                        predictionChart
                        recentDays
                    }

                    reminderCard

                    if subscriptionManager.isPro, !allEntries.isEmpty {
                        ShareLink(
                            item: HistoryCSVDocument(entries: allEntries),
                            preview: SharePreview("Energy Coach History", image: Image(systemName: "tablecells"))
                        ) {
                            Label("Export complete history as CSV", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                ProPaywallView(subscriptionManager: subscriptionManager)
            }
            .alert("Daily Reminder", isPresented: Binding(
                get: { reminderManager.errorMessage != nil },
                set: { if !$0 { reminderManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { reminderManager.errorMessage = nil }
            } message: {
                Text(reminderManager.errorMessage ?? "")
            }
        }
    }

    private var insightsDashboard: some View {
        historyCard(title: "Pro Insights", subtitle: selectedRange.rawValue) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                insightTile("Average score", value: "\(averageScore)", icon: "bolt.fill", color: .teal)
                insightTile("Trend", value: trendChange == 0 ? "Steady" : "\(trendChange > 0 ? "+" : "")\(trendChange)", icon: trendChange >= 0 ? "arrow.up.right" : "arrow.down.right", color: trendChange >= 0 ? .green : .orange)
                insightTile("Average sleep", value: String(format: "%.1fh", averageSleep), icon: "bed.double.fill", color: .indigo)
                insightTile("Average HRV", value: "\(averageHRV) ms", icon: "waveform.path.ecg", color: .cyan)
                insightTile("Resting HR", value: "\(averageRestingHeartRate) bpm", icon: "heart.fill", color: .pink)
                insightTile("Days tracked", value: "\(entries.count)", icon: "calendar", color: .blue)
            }

            if let bestDay, let lowestDay {
                Divider()
                dayHighlight("Best day", entry: bestDay, color: .green)
                dayHighlight("Lowest day", entry: lowestDay, color: .orange)
            }
        }
    }

    private var streakCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(checkInStreak)-day check-in streak")
                    .font(.headline)
                Text(checkInStreak == 0 ? "Save today's check-in to start your streak." : "Keep checking in to understand your prediction accuracy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))
    }

    private var reminderCard: some View {
        DailyReminderCard(manager: reminderManager)
    }

    private func insightTile(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }

    private func dayHighlight(_ title: String, entry: EnergyHistoryEntry, color: Color) -> some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Text(entry.date, format: .dateTime.day().month(.abbreviated))
                .foregroundStyle(.secondary)
            Text("\(entry.scoreOutOf100)")
                .font(.headline)
                .foregroundStyle(color)
        }
    }

    private var proBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Your latest 7 days are free", systemImage: "clock.arrow.circlepath")
                .font(.headline)
            Text("Energy Coach Pro unlocks unlimited history, longer-term trends, and long-term prediction comparisons.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Explore Energy Coach Pro") {
                isShowingPaywall = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.teal.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
    }

    private var scoreChart: some View {
        historyCard(title: "Daily Energy", subtitle: subscriptionManager.isPro ? selectedRange.rawValue : "Latest 7 days") {
            Chart(entries) { entry in
                LineMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Score", entry.scoreOutOf100)
                )
                .foregroundStyle(.teal)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Score", entry.scoreOutOf100)
                )
                .foregroundStyle(.teal)
            }
            .chartYScale(domain: 0...100)
            .frame(height: 220)
        }
    }

    private var predictionChart: some View {
        historyCard(title: "Prediction Check", subtitle: "Predicted compared with how you felt") {
            Chart(entries) { entry in
                BarMark(
                    x: .value("Day", entry.date, unit: .day),
                    y: .value("Energy", entry.predictedEnergyOutOf10)
                )
                .foregroundStyle(.teal.opacity(0.55))

                if let actual = entry.actualEnergyOutOf10 {
                    PointMark(
                        x: .value("Day", entry.date, unit: .day),
                        y: .value("Actual", actual)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(90)
                }
            }
            .chartYScale(domain: 0...10)
            .frame(height: 190)

            HStack(spacing: 18) {
                Label("Predicted", systemImage: "square.fill")
                    .foregroundStyle(.teal)
                Label("Actual", systemImage: "circle.fill")
                    .foregroundStyle(.blue)
            }
            .font(.caption)
        }
    }

    private var recentDays: some View {
        historyCard(title: "Recorded Days", subtitle: nil) {
            ForEach(entries.reversed()) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                            .font(.subheadline.weight(.semibold))
                        Text("Sleep \(entry.sleepHours, specifier: "%.1f")h • HRV \(Int(entry.heartRateVariability)) ms")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(entry.scoreOutOf100)")
                        .font(.title3.bold())
                        .foregroundStyle(.teal)
                }
                .padding(.vertical, 5)
            }
        }
    }

    private func historyCard<Content: View>(title: String, subtitle: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ProPaywallView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Image(systemName: "bolt.heart.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.teal)

                    VStack(spacing: 8) {
                        Text("Energy Coach Pro")
                            .font(.largeTitle.bold())
                        Text("Understand your patterns, not just today.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        feature("Unlimited energy history", icon: "calendar")
                        feature("Weekly and monthly trends", icon: "chart.line.uptrend.xyaxis")
                        feature("Prediction accuracy comparisons", icon: "scope")
                        feature("Long-term recovery and activity patterns", icon: "sparkles")
                        feature("CSV history export", icon: "square.and.arrow.up")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(Color.teal.opacity(0.10), in: RoundedRectangle(cornerRadius: 14))

                    if subscriptionManager.products.isEmpty {
                        if subscriptionManager.isLoading {
                            ProgressView("Loading subscriptions…")
                        } else {
                            Text("Subscriptions are not available yet.")
                                .foregroundStyle(.secondary)
                            Button("Try Again") {
                                Task { await subscriptionManager.loadProducts() }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        ForEach(subscriptionManager.products) { product in
                            Button {
                                Task { await subscriptionManager.purchase(product) }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(product.displayName)
                                            .font(.headline)
                                        Text(product.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    Spacer()
                                    Text(priceText(for: product))
                                        .font(.headline)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity)
                                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .disabled(subscriptionManager.isLoading)
                        }
                    }

                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                    .disabled(subscriptionManager.isLoading)

                    Link("Manage Subscription", destination: URL(string: "https://apps.apple.com/account/subscriptions")!)
                        .font(.footnote)

                    HStack(spacing: 18) {
                        Link("Privacy Policy", destination: URL(string: "https://matthew8750.github.io/EnergyCoachApp/privacy-policy.html")!)
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    }
                    .font(.footnote)

                    Text("Payment is charged to your Apple Account. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the current period. You can manage or cancel in your App Store account settings.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Energy Coach Pro", isPresented: Binding(
                get: { subscriptionManager.errorMessage != nil },
                set: { if !$0 { subscriptionManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { subscriptionManager.errorMessage = nil }
            } message: {
                Text(subscriptionManager.errorMessage ?? "")
            }
            .onChange(of: subscriptionManager.isPro) { _, isPro in
                if isPro { dismiss() }
            }
        }
    }

    private func feature(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
    }

    private func priceText(for product: Product) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return product.displayPrice
        }

        let unit: String
        switch period.unit {
        case .day: unit = period.value == 1 ? "day" : "\(period.value) days"
        case .week: unit = period.value == 1 ? "week" : "\(period.value) weeks"
        case .month: unit = period.value == 1 ? "month" : "\(period.value) months"
        case .year: unit = period.value == 1 ? "year" : "\(period.value) years"
        @unknown default: return product.displayPrice
        }

        return "\(product.displayPrice) / \(unit)"
    }
}

private struct DailyReminderCard: View {
    @ObservedObject var manager: DailyReminderManager
    @AppStorage("dailyReminderEnabled") private var isEnabled = false
    @AppStorage("dailyReminderHour") private var reminderHour = 9
    @AppStorage("dailyReminderMinute") private var reminderMinute = 0

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: reminderHour, minute: reminderMinute)) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? 9
                reminderMinute = components.minute ?? 0
                if isEnabled {
                    Task {
                        try? await manager.schedule(hour: reminderHour, minute: reminderMinute)
                    }
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: Binding(
                get: { isEnabled },
                set: { newValue in
                    if newValue {
                        Task {
                            isEnabled = await manager.enable(hour: reminderHour, minute: reminderMinute)
                        }
                    } else {
                        isEnabled = false
                        manager.disable()
                    }
                }
            )) {
                Label("Daily energy reminder", systemImage: "bell.badge")
                    .font(.headline)
            }
            .tint(.teal)

            if isEnabled {
                DatePicker("Reminder time", selection: reminderTime, displayedComponents: .hourAndMinute)
            } else {
                Text("Get a gentle reminder to view your score and save your daily check-in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
