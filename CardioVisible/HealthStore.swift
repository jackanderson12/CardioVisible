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
    case missingWalkRunDistanceType
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
    
    let endDate = Date()
    
    @Published var timeRange: TimeRange = .daily
    @Published var heartRateReading: HeartRateData
    @Published var walkingRunningData: WalkingRunningData
    
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
    
    var interval: DateComponents {
        switch timeRange {
        case .daily:
            return DateComponents(day: 1)
        case .weekly:
            return DateComponents(day: 7)
        case .monthly:
            return DateComponents(day: 30)
        case .yearly:
            return DateComponents(day: 365)
        }
    }
    
    init() {
        heartRateReading = HeartRateData()
        walkingRunningData = WalkingRunningData()
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
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
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
                
                statisticsCollection.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
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
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
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
                
                statisticsCollection.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
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
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
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
                
                statisticsCollection.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
                    if let averageQuantity = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                        localHeartRateData.resting = averageQuantity
                    }
                }
                
                continuation.resume(returning: localHeartRateData) // Return the local instance
            }
            
            healthStore?.execute(query)
        }
    }
    
    func fetchHeartRateData() async throws {
        async let restingRate = fetchRestingHeartRateData()
        async let minRate = fetchHeartMinRateData()
        async let maxRate = fetchHeartMaxRateData()
        do {
            self.heartRateReading.resting = try await restingRate.resting
            self.heartRateReading.minimum = try await minRate.minimum
            self.heartRateReading.maximum = try await maxRate.maximum
        } catch {
            // Handle errors
            throw error
        }
    }
    
    func fetchWalkingRunningAverageSpeedData() async throws -> WalkingRunningData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        guard let speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed) else {
            throw HealthError.missingWalkRunDistanceType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: speedType,
                    quantitySamplePredicate: predicate,
                    options: [.discreteAverage],
                    anchorDate: startDate,
                    intervalComponents: interval
                )

                query.initialResultsHandler = { _, statisticsCollection, error in
                    // ... existing error handling ...

                    var localWalkingRunningData = WalkingRunningData()
                    statisticsCollection?.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
                        localWalkingRunningData.averageSpeed = statistics.averageQuantity()?.doubleValue(for: HKUnit.mile().unitDivided(by: HKUnit.hour()))
                    }
                    continuation.resume(returning: localWalkingRunningData)
                }
                healthStore?.execute(query)
            }
    }
    
    func fetchWalkingRunningMaximumSpeedData() async throws -> WalkingRunningData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        guard let speedType = HKQuantityType.quantityType(forIdentifier: .runningSpeed) else {
            throw HealthError.missingWalkRunDistanceType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: speedType,
                    quantitySamplePredicate: predicate,
                    options: [.discreteMax],
                    anchorDate: startDate,
                    intervalComponents: interval
                )

                query.initialResultsHandler = { _, statisticsCollection, error in
                    // ... existing error handling ...

                    var localWalkingRunningData = WalkingRunningData()
                    statisticsCollection?.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
                        localWalkingRunningData.maximumSpeed = statistics.maximumQuantity()?.doubleValue(for: HKUnit.mile().unitDivided(by: HKUnit.hour()))
                    }
                    continuation.resume(returning: localWalkingRunningData)
                }
                healthStore?.execute(query)
            }
    }
    
    func fetchWalkingRunningTotalDistanceData() async throws -> WalkingRunningData {
        
        let predicate: NSPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        guard let walkingRunningDataType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthError.missingWalkRunDistanceType
        }
        
        return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsCollectionQuery(
                    quantityType: walkingRunningDataType,
                    quantitySamplePredicate: predicate,
                    options: [.cumulativeSum],
                    anchorDate: startDate,
                    intervalComponents: interval
                )

                query.initialResultsHandler = { _, statisticsCollection, error in
                    // ... existing error handling ...

                    var localWalkingRunningData = WalkingRunningData()
                    statisticsCollection?.enumerateStatistics(from: self.startDate, to: self.endDate) { statistics, _ in
                        localWalkingRunningData.distanceTraveled = statistics.sumQuantity()?.doubleValue(for: HKUnit.mile())
                    }
                    continuation.resume(returning: localWalkingRunningData)
                }
                healthStore?.execute(query)
            }
    }
    
    func fetchWalkingRunningData() async throws {
        async let averageSpeed = fetchWalkingRunningAverageSpeedData()
        async let maxSpeed = fetchWalkingRunningMaximumSpeedData()
        async let distanceTraveled = fetchWalkingRunningTotalDistanceData()
        do {
            self.walkingRunningData.averageSpeed = try await averageSpeed.averageSpeed
            self.walkingRunningData.maximumSpeed = try await maxSpeed.maximumSpeed
            self.walkingRunningData.distanceTraveled = try await distanceTraveled.distanceTraveled
        } catch {
            // Handle errors
            throw error
        }
    }
}

