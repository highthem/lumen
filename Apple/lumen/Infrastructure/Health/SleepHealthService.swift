import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Reads `.sleepAnalysis` samples from HealthKit and aggregates them into a
/// per-night summary. Read-only; never writes. All errors are swallowed and
/// surfaced as `nil`/`false` per the protocol contract.
final class SleepHealthService: SleepHealthProviding {
    #if canImport(HealthKit)
    private let store = HKHealthStore()
    #endif

    var isAuthorized: Bool {
        get async {
            #if canImport(HealthKit)
            guard HKHealthStore.isHealthDataAvailable() else { return false }
            guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
                return false
            }
            return store.authorizationStatus(for: type) == .sharingAuthorized
            #else
            return false
            #endif
        }
    }

    func requestAuthorization() async -> Bool {
        #if canImport(HealthKit)
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }
        do {
            try await store.requestAuthorization(toShare: [], read: [type])
            return await isAuthorized
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    func fetchLastNight() async -> SleepSummary? {
        #if canImport(HealthKit)
        guard await isAuthorized else { return nil }
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let end = Date()
        guard let start = Calendar.current.date(byAdding: .hour, value: -24, to: end) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let samples: [HKCategorySample]
        do {
            samples = try await fetchSamples(type: type, predicate: predicate, sort: [sort])
        } catch {
            return nil
        }

        var deep: TimeInterval = 0
        var rem: TimeInterval = 0
        var core: TimeInterval = 0
        var awake: TimeInterval = 0
        var bedtime: Date?
        var wakeTime: Date?

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            // `.asleepUnspecified` is the value iPhone-only sleep tracking emits
            // when no Apple Watch is paired — bucket it as "core" so the user
            // still gets a populated card instead of an empty one.
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deep += duration
                bedtime = bedtime.map { min($0, sample.startDate) } ?? sample.startDate
                wakeTime = wakeTime.map { max($0, sample.endDate) } ?? sample.endDate
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                rem += duration
                bedtime = bedtime.map { min($0, sample.startDate) } ?? sample.startDate
                wakeTime = wakeTime.map { max($0, sample.endDate) } ?? sample.endDate
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                core += duration
                bedtime = bedtime.map { min($0, sample.startDate) } ?? sample.startDate
                wakeTime = wakeTime.map { max($0, sample.endDate) } ?? sample.endDate
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                awake += duration
            default:
                continue
            }
        }

        let totalAsleep = deep + rem + core
        guard totalAsleep > 0, let bedtime, let wakeTime else { return nil }

        return SleepSummary(
            bedtime: bedtime,
            wakeTime: wakeTime,
            totalAsleep: totalAsleep,
            deep: deep,
            rem: rem,
            core: core,
            awake: awake
        )
        #else
        return nil
        #endif
    }

    #if canImport(HealthKit)
    private func fetchSamples(
        type: HKCategoryType,
        predicate: NSPredicate,
        sort: [NSSortDescriptor]
    ) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: sort
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.healthStore_executeOrQueue(query)
        }
    }
    #endif
}

#if canImport(HealthKit)
private extension HKHealthStore {
    func healthStore_executeOrQueue(_ query: HKQuery) {
        execute(query)
    }
}
#endif
