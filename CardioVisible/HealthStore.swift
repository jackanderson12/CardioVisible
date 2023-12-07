//
//  HealthStore.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import Foundation
import HealthKit

enum HealthError: Error {
    case healthDataNotAvailable
    case missingHeartRateType
    case queryFailed
}

enum TimeRange: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { self.rawValue }
}


struct HealthConstants {
    static let calendar: Calendar = Calendar(identifier: .gregorian)
    static let endDate: Date = Date()
    static var startDate: Date = calendar.startOfDay(for: endDate)
    static let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
    static let interval: DateComponents = DateComponents(day: 1)
    
    mutating func updateTimeRange(to range: TimeRange) {
        let calendar = Calendar.current
        switch range {
        case .daily:
            HealthConstants.startDate = calendar.startOfDay(for: HealthConstants.endDate)
        case .weekly:
            HealthConstants.startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: HealthConstants.endDate) ?? Date()
        case .monthly:
            HealthConstants.startDate = calendar.date(byAdding: .month, value: -1, to: HealthConstants.endDate) ?? Date()
        case .yearly:
            HealthConstants.startDate = calendar.date(byAdding: .year, value: -1, to: HealthConstants.endDate) ?? Date()
        }
    }
}


@MainActor
class HealthStore: ObservableObject {
    
    @Published var heartRateReading: HeartRateData?
    @Published var startTimeRange: TimeRange?
    @Published var healthConstants = HealthConstants()
    
    var healthStore: HKHealthStore?
    var lastError: Error?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            lastError = HealthError.healthDataNotAvailable
        }
    }
    
    func requestAuthorization() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        guard let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return }
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        guard let speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed) else { return }
        
        guard let healthStore = self.healthStore else { return }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [heartRateType, restingHeartRateType, distanceType, speedType])
        } catch {
            lastError = error
        }
    }
    
    func fetchHeartMinRateData() async throws -> HeartRateData {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: HealthConstants.predicate,
                options: .discreteMin,
                anchorDate: HealthConstants.startDate,
                intervalComponents: HealthConstants.interval
            )
            
            query.initialResultsHandler = { _, statisticsCollection, error in
                if let error = error {
                    print("Query error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statisticsCollection = statisticsCollection else {
                    print("No statistics collection found")
                    continuation.resume(throwing: HealthError.queryFailed)
                    return
                }
                
                var localHeartRateData = HeartRateData() // Local instance
                
                statisticsCollection.enumerateStatistics(from: HealthConstants.startDate, to: HealthConstants.endDate) { statistics, _ in
                    if let minimumQuantity = statistics.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.minimum = minimumQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchHeartMaxRateData() async throws -> HeartRateData {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: HealthConstants.predicate,
                options: .discreteMax,
                anchorDate: HealthConstants.startDate,
                intervalComponents: HealthConstants.interval
            )
            
            query.initialResultsHandler = { _, statisticsCollection, error in
                if let error = error {
                    print("Query error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statisticsCollection = statisticsCollection else {
                    print("No statistics collection found")
                    continuation.resume(throwing: HealthError.queryFailed)
                    return
                }
                
                var localHeartRateData = HeartRateData() // Local instance
                
                statisticsCollection.enumerateStatistics(from: HealthConstants.startDate, to: HealthConstants.endDate) { statistics, _ in
                    if let maximumQuantity = statistics.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.maximum = maximumQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchRestingHeartRateData() async throws -> HeartRateData {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: HealthConstants.predicate,
                options: [.discreteAverage],
                anchorDate: HealthConstants.startDate,
                intervalComponents: HealthConstants.interval
            )
            
            query.initialResultsHandler = { _, statisticsCollection, error in
                if let error = error {
                    print("Query error: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statisticsCollection = statisticsCollection else {
                    print("No statistics collection found")
                    continuation.resume(throwing: HealthError.queryFailed)
                    return
                }
                
                var localHeartRateData = HeartRateData() // Local instance
                
                statisticsCollection.enumerateStatistics(from: HealthConstants.startDate, to: HealthConstants.endDate) { statistics, _ in
                    if let averageQuantity = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.resting = averageQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchHeartRateData() async throws -> HeartRateData {
        async let restingRate = fetchRestingHeartRateData()
        async let minRate = fetchHeartMinRateData()
        async let maxRate = fetchHeartMaxRateData()
        
        var combinedData = HeartRateData()
        do {
            combinedData.resting = try await restingRate.resting
            combinedData.minimum = try await minRate.minimum
            combinedData.maximum = try await maxRate.maximum
            return combinedData
        } catch {
            // Handle errors
            throw error
        }
    }
    
    func updateTimeRange(to range: TimeRange) {
        healthConstants.updateTimeRange(to: range)
        // Trigger data fetching here
        Task {
            try await fetchHeartRateData()
        }
    }
}

