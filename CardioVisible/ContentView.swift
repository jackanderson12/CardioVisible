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
    @State private var selectedTimeRange: TimeRange = .daily
    @State private var minimum: Double?
    @State private var maximum: Double?
    @State private var resting: Double?
    
    var body: some View {
        ZStack {
            if let heartRateData = healthStore.heartRateReading {
                VStack {
                    Picker("Select Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .onChange(of: selectedTimeRange, {
                        Task {
                            healthStore.updateTimeRange(to: selectedTimeRange, from: healthStore.endDate)
                            healthStore.heartRateReading = try await healthStore.fetchHeartRateData()
                            maximum = healthStore.heartRateReading?.maximum
                            minimum = healthStore.heartRateReading?.minimum
                            resting = healthStore.heartRateReading?.resting
                        }
                    })
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    Spacer()
                    Spacer()
                    Button(action: {
                        selectedRate = heartRateData.resting
                    }, label: {
                        Text("Resting Heart Rate: \(Int(resting ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 5)
                    })
                    Button(action: {
                        selectedRate = heartRateData.minimum
                    }, label: {
                        Text("Minimum Heart Rate: \(Int(minimum ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 5)
                    })
                    Button(action: {
                        selectedRate = heartRateData.maximum
                    }, label: {
                        Text("Maximum Heart Rate: \(Int(maximum ?? 0)) BPM")
                            .bold()
                            .padding(.bottom, 35)
                    })
                } .zIndex(1.0)
                
                if let rate = selectedRate {
                    HeartBeat3DView(rate: rate)
                        .padding(.top, 50)
                }
                
            } else {
                Text("Loading heart rate data...")
            }
            
        }
        .background(.black)
        .ignoresSafeArea(edges: .all)
        .task {
            await healthStore.requestAuthorization()
            do {
                healthStore.heartRateReading = try await healthStore.fetchHeartRateData()
                maximum = healthStore.heartRateReading?.maximum
                minimum = healthStore.heartRateReading?.minimum
                resting = healthStore.heartRateReading?.resting
            } catch {
                // Handle the error, e.g., show an error message to the user
            }
        }
    }
}

#Preview {
    ContentView()
}
