import Foundation
import CoreTransferable
import UniformTypeIdentifiers

struct EnergyHistoryEntry: Codable, Equatable, Identifiable {
    var id: String { dayKey }

    let dayKey: String
    let date: Date
    let scoreOutOf100: Int
    let predictedEnergyOutOf10: Int
    let actualEnergyOutOf10: Int?
    let sleepHours: Double
    let restingHeartRate: Int
    let heartRateVariability: Double
    let activeEnergyBurned: Int
}

struct HistoryCSVDocument: Transferable {
    let entries: [EnergyHistoryEntry]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { document in
            Data(document.csv.utf8)
        }
        .suggestedFileName("Energy-Coach-History.csv")
    }

    private var csv: String {
        let formatter = ISO8601DateFormatter()
        let header = "date,score,predicted_energy,actual_energy,sleep_hours,resting_heart_rate,hrv,active_energy"
        let rows = entries.map { entry in
            [
                formatter.string(from: entry.date),
                String(entry.scoreOutOf100),
                String(entry.predictedEnergyOutOf10),
                entry.actualEnergyOutOf10.map(String.init) ?? "",
                String(format: "%.1f", entry.sleepHours),
                String(entry.restingHeartRate),
                String(format: "%.0f", entry.heartRateVariability),
                String(entry.activeEnergyBurned)
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}

@MainActor
final class HistoryStore: ObservableObject {
    @Published private(set) var entries: [EnergyHistoryEntry] = []

    private let defaults: UserDefaults
    private let storageKey = "energyCoach.history.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func upsert(_ entry: EnergyHistoryEntry) {
        if let index = entries.firstIndex(where: { $0.dayKey == entry.dayKey }) {
            guard entries[index] != entry else { return }
            entries[index] = entry
        } else {
            entries.append(entry)
        }

        entries.sort { $0.date < $1.date }
        save()
    }

    func visibleEntries(isPro: Bool, calendar: Calendar = .current, now: Date = .now) -> [EnergyHistoryEntry] {
        guard !isPro,
              let cutoff = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) else {
            return entries
        }

        return entries.filter { $0.date >= cutoff }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? decoder.decode([EnergyHistoryEntry].self, from: data) else {
            return
        }

        entries = decoded.sorted { $0.date < $1.date }
    }

    private func save() {
        guard let data = try? encoder.encode(entries) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
