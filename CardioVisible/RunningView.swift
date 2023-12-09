//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct RunningView: View {
    
    @StateObject var healthStore = HealthStore.shared
    @State private var selectedTimeRange: TimeRange = .daily
    @State private var selectedSpeed: Double? = 0.0
    @State private var averageSpeed: Double?
    @State private var maximumSpeed: Double?
    @State private var totalDistance: Double?
    
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
                    selectedSpeed = averageSpeed
                }, label: {
                    Text("Average Speed: \(Int(averageSpeed ?? 0)) MPH")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    selectedSpeed = maximumSpeed
                }, label: {
                    Text("Maximum Speed: \(Int(maximumSpeed ?? 0)) MPH")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    
                }, label: {
                    Text("Total Distance Traveled: \(Int(totalDistance ?? 0)) Miles")
                        .bold()
                        .padding(.bottom, 100)
                })
            } .zIndex(1.0)
            
            if let speed = selectedSpeed {
                Running3DView(speed: speed)
                    .padding()
            }
        }
        .background(.black)
        .ignoresSafeArea(edges: .all)
        .task {
            await healthStore.requestAuthorization()
            do {
                try await healthStore.fetchHeartRateData()

            } catch {
                // Handle the error, e.g., show an error message to the user
            }
        }
        .onChange(of: selectedTimeRange, {
            Task {
                healthStore.timeRange = selectedTimeRange
                try await healthStore.fetchWalkingRunningData()
                averageSpeed = healthStore.walkingRunningData.averageSpeed
                maximumSpeed = healthStore.walkingRunningData.maximumSpeed
                totalDistance = healthStore.walkingRunningData.distanceTraveled
            }
        })
    }
}

#Preview {
    RunningView()
}
