//
//  HealthStore.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import Foundation
import HealthKit
import Observation

enum HealthError: Error {
    case healthDataNotAvailable
}

@Observable
class HealthStore {
    
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
        let heartRateType = HKQuantityType(.heartRate)
        let distanceType = HKQuantityType(.distanceWalkingRunning)
        let speedType = HKQuantityType(.runningSpeed)
        
        guard let healthStore = self.healthStore else { return }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: [heartRateType, distanceType, speedType])
        } catch {
            lastError = error
        }
    }
    
}
