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

@MainActor
class HealthStore: ObservableObject {
    
    static let shared = HealthStore()
    
    @Published var timeRange: TimeRange = .daily
    @Published var heartRateReading: HeartRateData
    
    var healthStore: HKHealthStore?
    var lastError: Error?
    
    var startDate: Date {
        switch timeRange {
        case .daily:
            return Calendar.current.startOfDay(for: Date())
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        case .yearly:
            return Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        }
    }
    
    var endDate: Date = Date()
    
    init() {
        heartRateReading = HeartRateData()
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
    
    func fetchHeartMinRateData(startDate: Date, endDate: Date) async throws -> HeartRateData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let interval: DateComponents = DateComponents(day: 1)
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteMin,
                anchorDate: startDate,
                intervalComponents: interval
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
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let minimumQuantity = statistics.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.minimum = minimumQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchHeartMaxRateData(startDate: Date, endDate: Date) async throws -> HeartRateData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let interval: DateComponents = DateComponents(day: 1)
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteMax,
                anchorDate: startDate,
                intervalComponents: interval
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
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let maximumQuantity = statistics.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.maximum = maximumQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchRestingHeartRateData(startDate: Date, endDate: Date) async throws -> HeartRateData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let interval: DateComponents = DateComponents(day: 1)
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthError.missingHeartRateType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: startDate,
                intervalComponents: interval
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
                
                statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
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
        async let restingRate = fetchRestingHeartRateData(startDate: startDate, endDate: endDate)
        async let minRate = fetchHeartMinRateData(startDate: startDate, endDate: endDate)
        async let maxRate = fetchHeartMaxRateData(startDate: startDate, endDate: endDate)
        do {
            heartRateReading.resting = try await restingRate.resting
            heartRateReading.minimum = try await minRate.minimum
            heartRateReading.maximum = try await maxRate.maximum
        } catch {
            // Handle errors
            throw error
        }
        return heartRateReading
    }
}

