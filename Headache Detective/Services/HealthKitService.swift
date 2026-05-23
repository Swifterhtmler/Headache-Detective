import HealthKit
import Foundation

enum HealthKitError: Error {
    case notAvailable
    case notAuthorized
}

@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let store: HKHealthStore?

    private init() {
        guard HKHealthStore.isHealthDataAvailable() else {
            store = nil
            return
        }
        store = HKHealthStore()
    }

    var isAvailable: Bool {
        store != nil
    }

    private var headacheType: HKCategoryType {
        HKObjectType.categoryType(forIdentifier: .headache)!
    }

    func requestAuthorization() async throws {
        guard let store else { throw HealthKitError.notAvailable }
        let types: Set = [headacheType]
        try await store.requestAuthorization(toShare: types, read: [])
    }

    func logHeadache(painLevel: Int, start: Date, end: Date) async throws {
        guard let store else { throw HealthKitError.notAvailable }

        let severity: HKCategoryValueSeverity
        switch painLevel {
        case 1...3:  severity = .mild
        case 4...6:  severity = .moderate
        case 7...10: severity = .severe
        default:     severity = .unspecified
        }

        let sample = HKCategorySample(
            type: headacheType,
            value: severity.rawValue,
            start: start,
            end: end
        )

        try await store.save(sample)
    }
}
