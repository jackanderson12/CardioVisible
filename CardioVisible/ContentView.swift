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
    
    var body: some View {
        ZStack {
            if let heartRateData = healthStore.heartRateReading {
                VStack {
                    Picker("Select Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .padding(.top, 60)
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: selectedTimeRange) {
                        Task {
                            do {
                                try await healthStore.heartRateReading = healthStore.updateTimeRange(to: selectedTimeRange)
                            } catch {
                                // Handle the error, e.g., show an error message to the user
                            }
                        }
                    }
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
                
            } catch {
                // Handle the error, e.g., show an error message to the user
            }
        }
    }
}

#Preview {
    ContentView()
}
