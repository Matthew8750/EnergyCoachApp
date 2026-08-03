//
//  EnergyCoachTests.swift
//  EnergyCoachTests
//
//  Created by helen robinson on 11/07/2026.
//

import Foundation
import Testing
@testable import EnergyCoach

struct EnergyCoachTests {
    @Test @MainActor
    func historyUpsertsOneEntryPerDay() {
        let defaults = makeDefaults()
        let store = HistoryStore(defaults: defaults)
        let original = makeEntry(dayKey: "2026-08-03", score: 60)
        let updated = makeEntry(dayKey: "2026-08-03", score: 82)

        store.upsert(original)
        store.upsert(updated)

        #expect(store.entries.count == 1)
        #expect(store.entries.first?.scoreOutOf100 == 82)
    }

    @Test @MainActor
    func freeHistoryOnlyShowsLatestSevenCalendarDays() {
        let defaults = makeDefaults()
        let store = HistoryStore(defaults: defaults)
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_775_347_200) // 2026-04-06 UTC

        for offset in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -offset, to: now)!
            store.upsert(makeEntry(dayKey: "day-\(offset)", score: 70 + offset, date: date))
        }

        #expect(store.visibleEntries(isPro: false, calendar: calendar, now: now).count == 7)
        #expect(store.visibleEntries(isPro: true, calendar: calendar, now: now).count == 10)
    }

    @MainActor
    private func makeDefaults() -> UserDefaults {
        let suiteName = "EnergyCoachTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeEntry(dayKey: String, score: Int, date: Date = .now) -> EnergyHistoryEntry {
        EnergyHistoryEntry(
            dayKey: dayKey,
            date: date,
            scoreOutOf100: score,
            predictedEnergyOutOf10: 7,
            actualEnergyOutOf10: nil,
            sleepHours: 7.5,
            restingHeartRate: 60,
            heartRateVariability: 55,
            activeEnergyBurned: 500
        )
    }
}
