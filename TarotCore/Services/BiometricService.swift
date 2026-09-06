import Foundation
import HealthKit
import Combine

/// Service that integrates with HealthKit to monitor the user's heart rate and derive their spiritual/emotional state.
public final class BiometricService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published public private(set) var currentHeartRate: Double = 0.0
    @Published public private(set) var soulState: SoulState = .unknown

    public init() {
        // Authorization is typically handled at a specific user-triggered point,
        // but we'll provide the method here.
    }

    /// Requests authorization to read heart rate data.
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw BiometricError.healthDataUnavailable
        }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let readTypes: Set = [heartRateType]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    /// Starts monitoring heart rate updates.
    public func startMonitoring() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        // Use an anchored object query to get the most recent samples
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] anchor, samples, deletedObjects, newAnchor, error in
            self?.processSamples(samples)
        }

        // Set up the handler for subsequent updates
        query.updateHandler = { [weak self] anchor, samples, deletedObjects, newAnchor, error in
            self?.processSamples(samples)
        }

        healthStore.execute(query)
    }

    private func processSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let lastSample = samples.last else { return }

        let bpm = lastSample.quantity.doubleValue(for: HKUnit(from: "count/min"))

        DispatchQueue.main.async {
            self.currentHeartRate = bpm
            self.updateSoulState(bpm: bpm)
        }
    }

    private func updateSoulState(bpm: Double) {
        if bpm == 0 {
            soulState = .unknown
            return
        }

        // Simple thresholds for demonstration; in a real app, these would be personalized
        if bpm < 65 {
            soulState = .calm
        } else if bpm < 90 {
            soulState = .elevated
        } else {
            soulState = .stressed
        }
    }

    public enum BiometricError: LocalizedError {
        case healthDataUnavailable

        public var errorDescription: String? {
            switch self {
            case .healthDataUnavailable: return "Health data is not available on this device."
            }
        }
    }
}
