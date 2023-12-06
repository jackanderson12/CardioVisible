//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var healthStore = HealthStore()
    @State private var selectedRate: Double? = 0.0
    
    var body: some View {
        ZStack {
            if let heartRateData = healthStore.heartRateReading {
                VStack {
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Button(action: {
                        selectedRate = heartRateData.resting
                    }, label: {
                        Text("Resting Heart Rate: \(Int(heartRateData.resting ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 5)
                    })
                    Button(action: {
                        selectedRate = heartRateData.minimum
                    }, label: {
                        Text("Minimum Heart Rate: \(Int(heartRateData.minimum ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 5)
                    })
                    Button(action: {
                        selectedRate = heartRateData.maximum
                    }, label: {
                        Text("Maximum Heart Rate: \(Int(heartRateData.maximum ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 5)
                    })
                } .zIndex(1.0)
                
                if let rate = selectedRate {
                    HeartBeat3DView(rate: rate)
                }
                
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
