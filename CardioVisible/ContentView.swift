//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var healthStore = HealthStore()  // Use StateObject for observed objects

    var body: some View {
        VStack {
            Image(systemName: "heart")
                .imageScale(.large)
                .foregroundStyle(.tint)

            if let heartRateData = healthStore.heartRateReading {
                Text("Average Heart Rate This Week: \(Int(heartRateData.average ?? 0)) BPM")
                Text("Maximum Heart Rate This Week: \(Int(heartRateData.maximum ?? 0)) BPM")
                Text("Minimum Heart Rate This Week: \(Int(heartRateData.minimum ?? 0)) BPM")
            } else {
                Text("Loading heart rate data...")
            }
        }
        .padding()
        .task {
            await healthStore.requestAuthorization()
            do {
                healthStore.heartRateReading = try await healthStore.fetchHeartRateData()
            } catch {
                // Handle the error, e.g., show an error message to the user
            }
        }
    }
}


#Preview {
    ContentView()
}
