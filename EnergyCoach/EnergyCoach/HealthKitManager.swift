//
//  HealthKitManager.swift
//  EnergyCoach
//
//  Created by Codex on 14/07/2026.
//

import Foundation
import EnergyAppBrainCore

#if canImport(HealthKit)
import HealthKit
#endif

struct HealthSnapshot {
    var bodyProfile: BodyProfile?
    var sleepHours: Double?
    var sleepQuality: SleepQualityMetrics?
    var hoursAwake: Double?
    var lastWakeTime: Date?
    var restingHeartRate: Int?
    var heartRateVariability: Double?
    var respiratoryRate: Double?
    var oxygenSaturation: Double?
    var walkingHeartRateAverage: Int?
    var steps: Int?
    var activeEnergyBurned: Int?
    var exerciseMinutes: Int?
    var standMinutes: Int?
    var dietaryEnergyConsumed: Int?
    var personalBaselines: PersonalBaselines?
}

@MainActor
final class HealthKitManager: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(String)
        case failed(String)
    }

    @Published private(set) var state: LoadState = .idle

#if canImport(HealthKit)
    private let healthStore = HKHealthStore()

    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAndLoadToday() async -> HealthSnapshot? {
        guard isHealthDataAvailable else {
            state = .failed("Health data is not available on this device.")
            return nil
        }

        state = .loading

        do {
            try await requestAuthorization()
            let snapshot = await loadToday()
            state = .loaded("Updated from Apple Health. Missing Watch signals will fill in when Health has permission and data for them.")
            return snapshot
        } catch {
            state = .failed(error.localizedDescription)
            return nil
        }
    }

    private func requestAuthorization() async throws {
        let readTypes = Set([
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            HKObjectType.quantityType(forIdentifier: .restingHeartRate),
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN),
            HKObjectType.quantityType(forIdentifier: .respiratoryRate),
            HKObjectType.quantityType(forIdentifier: .oxygenSaturation),
            HKObjectType.quantityType(forIdentifier: .walkingHeartRateAverage),
            HKObjectType.quantityType(forIdentifier: .stepCount),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed),
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime),
            HKObjectType.quantityType(forIdentifier: .appleStandTime),
            HKObjectType.quantityType(forIdentifier: .height),
            HKObjectType.quantityType(forIdentifier: .bodyMass),
            HKObjectType.characteristicType(forIdentifier: .dateOfBirth),
            HKObjectType.characteristicType(forIdentifier: .biologicalSex)
        ].compactMap { $0 })

        let _: Void = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                }
            }
        }
    }

    private func loadToday() async -> HealthSnapshot {
        async let bodyProfile = loadBodyProfile()
        async let baselines = loadPersonalBaselines()
        async let sleep = optionalSleepSummarySinceYesterdayEvening()
        async let restingHeartRate = optionalMostRecentQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            since: .startOfDay
        )
        async let heartRateVariability = optionalMostRecentQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            since: .startOfDay
        )
        async let respiratoryRate = optionalMostRecentQuantity(
            identifier: .respiratoryRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            since: .hoursBack(36)
        )
        async let oxygenSaturation = optionalMostRecentQuantity(
            identifier: .oxygenSaturation,
            unit: .percent(),
            since: .hoursBack(36)
        )
        async let walkingHeartRateAverage = optionalMostRecentQuantity(
            identifier: .walkingHeartRateAverage,
            unit: HKUnit.count().unitDivided(by: .minute()),
            since: .startOfDay
        )
        async let steps = optionalSumQuantity(
            identifier: .stepCount,
            unit: .count(),
            since: .startOfDay
        )
        async let activeEnergyBurned = optionalSumQuantity(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            since: .startOfDay
        )
        async let dietaryEnergyConsumed = optionalSumQuantity(
            identifier: .dietaryEnergyConsumed,
            unit: .kilocalorie(),
            since: .startOfDay
        )
        async let exerciseMinutes = optionalSumQuantity(
            identifier: .appleExerciseTime,
            unit: .minute(),
            since: .startOfDay
        )
        async let standMinutes = optionalSumQuantity(
            identifier: .appleStandTime,
            unit: .minute(),
            since: .startOfDay
        )

        let sleepSummary = await sleep

        return HealthSnapshot(
            bodyProfile: await bodyProfile,
            sleepHours: sleepSummary?.hours,
            sleepQuality: sleepSummary?.quality,
            hoursAwake: sleepSummary?.hoursAwake,
            lastWakeTime: sleepSummary?.wakeTime,
            restingHeartRate: await restingHeartRate.map { Int($0.rounded()) },
            heartRateVariability: await heartRateVariability,
            respiratoryRate: await respiratoryRate,
            oxygenSaturation: await oxygenSaturation,
            walkingHeartRateAverage: await walkingHeartRateAverage.map { Int($0.rounded()) },
            steps: await steps.map { Int($0.rounded()) },
            activeEnergyBurned: await activeEnergyBurned.map { Int($0.rounded()) },
            exerciseMinutes: await exerciseMinutes.map { Int($0.rounded()) },
            standMinutes: await standMinutes.map { Int($0.rounded()) },
            dietaryEnergyConsumed: await dietaryEnergyConsumed.map { Int($0.rounded()) },
            personalBaselines: await baselines
        )
    }

    private func optionalMostRecentQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async -> Double? {
        try? await mostRecentQuantity(identifier: identifier, unit: unit, since: dateBoundary)
    }

    private func optionalSumQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async -> Double? {
        try? await sumQuantity(identifier: identifier, unit: unit, since: dateBoundary)
    }

    private func optionalAverageQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async -> Double? {
        try? await averageQuantity(identifier: identifier, unit: unit, since: dateBoundary)
    }

    private func optionalSleepSummarySinceYesterdayEvening() async -> SleepSummary? {
        try? await sleepSummarySinceYesterdayEvening()
    }

    private func mostRecentQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async throws -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        let predicate = predicate(since: dateBoundary)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func sumQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async throws -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate(since: dateBoundary),
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func averageQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        since dateBoundary: DateBoundary
    ) async throws -> Double? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: identifier) else {
            return nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate(since: dateBoundary),
                options: .discreteAverage
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume(returning: statistics?.averageQuantity()?.doubleValue(for: unit))
            }

            healthStore.execute(query)
        }
    }

    private func sleepSummarySinceYesterdayEvening() async throws -> SleepSummary? {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .hour, value: -36, to: Date()) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictEndDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let sleepSamples = samples as? [HKCategorySample] ?? []
                let asleepSamples = sleepSamples.filter { Self.isAsleepValue($0.value) }

                let sleepSeconds = asleepSamples.reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                guard sleepSeconds > 0 else {
                    continuation.resume(returning: nil)
                    return
                }

                let awakeSeconds = sleepSamples
                    .filter { Self.isAwakeValue($0.value) }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                let timeInBedSeconds = sleepSeconds + awakeSeconds
                let sleepEfficiency = timeInBedSeconds > 0 ? sleepSeconds / timeInBedSeconds : nil
                let quality = SleepQualityMetrics(
                    deepSleepHours: Self.hours(for: .asleepDeep, in: sleepSamples),
                    remSleepHours: Self.hours(for: .asleepREM, in: sleepSamples),
                    coreSleepHours: Self.hours(for: .asleepCore, in: sleepSamples),
                    awakeDuringSleepHours: awakeSeconds > 0 ? awakeSeconds / 3_600 : nil,
                    sleepEfficiency: sleepEfficiency
                )

                let wakeTime = asleepSamples.map(\.endDate).max()
                let hoursAwake = wakeTime.map { max(0, Date().timeIntervalSince($0) / 3_600) }
                continuation.resume(
                    returning: SleepSummary(
                        hours: sleepSeconds / 3_600,
                        quality: quality,
                        hoursAwake: hoursAwake,
                        wakeTime: wakeTime
                    )
                )
            }

            healthStore.execute(query)
        }
    }

    private func loadPersonalBaselines() async -> PersonalBaselines {
        async let sleepHours = averageSleepHours(daysBack: 30)
        async let restingHeartRate = optionalAverageQuantity(
            identifier: .restingHeartRate,
            unit: HKUnit.count().unitDivided(by: .minute()),
            since: .daysBack(30)
        )
        async let heartRateVariability = optionalAverageQuantity(
            identifier: .heartRateVariabilitySDNN,
            unit: .secondUnit(with: .milli),
            since: .daysBack(30)
        )
        async let activeEnergyBurned = averageDailySumQuantity(
            identifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            daysBack: 30
        )

        return PersonalBaselines(
            sleepHours: await sleepHours,
            restingHeartRate: await restingHeartRate.map { Int($0.rounded()) },
            heartRateVariability: await heartRateVariability,
            activeEnergyBurned: await activeEnergyBurned.map { Int($0.rounded()) }
        )
    }

    private func averageDailySumQuantity(
        identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        daysBack: Int
    ) async -> Double? {
        guard
            daysBack > 0,
            let total = await optionalSumQuantity(identifier: identifier, unit: unit, since: .daysBack(daysBack))
        else {
            return nil
        }

        return total / Double(daysBack)
    }

    private func averageSleepHours(daysBack: Int) async -> Double? {
        guard
            daysBack > 0,
            let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
            let start = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())
        else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictEndDate
        )
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let sleepSamples = (samples as? [HKCategorySample] ?? [])
                    .filter { Self.isAsleepValue($0.value) }
                let calendar = Calendar.current
                var secondsByDay: [Date: TimeInterval] = [:]

                for sample in sleepSamples {
                    let day = calendar.startOfDay(for: sample.endDate)
                    secondsByDay[day, default: 0] += sample.endDate.timeIntervalSince(sample.startDate)
                }

                let daysWithSleep = secondsByDay.filter { $0.value > 0 }
                guard !daysWithSleep.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let averageSeconds = daysWithSleep.values.reduce(0, +) / Double(daysWithSleep.count)
                continuation.resume(returning: averageSeconds / 3_600)
            }

            healthStore.execute(query)
        }
    }

    private func predicate(since dateBoundary: DateBoundary) -> NSPredicate? {
        let calendar = Calendar.current
        let start: Date

        switch dateBoundary {
        case .allTime:
            return nil
        case .startOfDay:
            start = calendar.startOfDay(for: Date())
        case .hoursBack(let hours):
            start = calendar.date(byAdding: .minute, value: Int(-hours * 60), to: Date()) ?? Date()
        case .daysBack(let days):
            start = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }

        return HKQuery.predicateForSamples(
            withStart: start,
            end: Date(),
            options: .strictStartDate
        )
    }

    private func loadBodyProfile() async -> BodyProfile {
        async let height = optionalMostRecentQuantity(
            identifier: .height,
            unit: .meterUnit(with: .centi),
            since: .allTime
        )
        async let weight = optionalMostRecentQuantity(
            identifier: .bodyMass,
            unit: .gramUnit(with: .kilo),
            since: .allTime
        )

        return BodyProfile(
            age: try? loadAge(),
            biologicalSex: try? loadBiologicalSex(),
            heightCentimeters: await height,
            weightKilograms: await weight
        )
    }

    private func loadAge() throws -> Int? {
        let components = try healthStore.dateOfBirthComponents()
        guard let birthDate = Calendar.current.date(from: components) else {
            return nil
        }

        return Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year
    }

    private func loadBiologicalSex() throws -> BiologicalSex? {
        switch try healthStore.biologicalSex().biologicalSex {
        case .female:
            return .female
        case .male:
            return .male
        case .other:
            return .other
        case .notSet:
            return .notSet
        @unknown default:
            return .notSet
        }
    }

    nonisolated private static func isAsleepValue(_ value: Int) -> Bool {
        value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
            || value == HKCategoryValueSleepAnalysis.asleepCore.rawValue
            || value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            || value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
    }

    nonisolated private static func isAwakeValue(_ value: Int) -> Bool {
        value == HKCategoryValueSleepAnalysis.awake.rawValue
    }

    nonisolated private static func hours(
        for stage: HKCategoryValueSleepAnalysis,
        in samples: [HKCategorySample]
    ) -> Double? {
        let seconds = samples
            .filter { $0.value == stage.rawValue }
            .reduce(0.0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }

        return seconds > 0 ? seconds / 3_600 : nil
    }
#else
    var isHealthDataAvailable: Bool {
        false
    }

    func requestAndLoadToday() async -> HealthSnapshot? {
        state = .failed("HealthKit is not available in this build.")
        return nil
    }
#endif
}

private struct SleepSummary {
    let hours: Double
    let quality: SleepQualityMetrics?
    let hoursAwake: Double?
    let wakeTime: Date?
}

private enum DateBoundary {
    case allTime
    case startOfDay
    case hoursBack(Double)
    case daysBack(Int)
}

private enum HealthKitError: LocalizedError {
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Health access was not granted."
        }
    }
}
