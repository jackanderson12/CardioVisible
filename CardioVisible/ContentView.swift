//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var healthStore = HealthStore.shared
    @State private var selectedRate: Double? = 0.0
    @State private var selectedTimeRange: TimeRange = .daily
    @State private var minimum: Double?
    @State private var maximum: Double?
    @State private var resting: Double?
    
    var body: some View {
        ZStack {
            VStack {
                Picker("Select Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
                Spacer()
                Spacer()
                Button(action: {
                    selectedRate = healthStore.heartRateReading.resting
                }, label: {
                    Text("Resting Heart Rate: \(Int(resting ?? 0)) BPM")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    selectedRate = healthStore.heartRateReading.minimum
                }, label: {
                    Text("Minimum Heart Rate: \(Int(minimum ?? 0)) BPM")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    selectedRate = healthStore.heartRateReading.maximum
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
            
        }
        .background(.black)
        .ignoresSafeArea(edges: .all)
        .task {
            await healthStore.requestAuthorization()
            do {
                try await healthStore.heartRateReading = healthStore.fetchHeartRateData()
                maximum = healthStore.heartRateReading.maximum
                minimum = healthStore.heartRateReading.minimum
                resting = healthStore.heartRateReading.resting
            } catch {
                // Handle the error, e.g., show an error message to the user
            }
        }
        .onChange(of: selectedTimeRange, {
            Task {
                healthStore.timeRange = selectedTimeRange
                healthStore.heartRateReading = try await healthStore.fetchHeartRateData()
                print(healthStore.heartRateReading.resting!)
                print(healthStore.heartRateReading.minimum!)
                print(healthStore.heartRateReading.maximum!)
            }
        })
    }
}

#Preview {
    ContentView()
}
