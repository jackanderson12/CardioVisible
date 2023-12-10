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
    @State private var displayGlobe: Bool = false
    
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
                if displayGlobe {
                    Text(calculatePercentageAroundGlobe(milesRun: totalDistance ?? 0))
                        .padding(.bottom, 5)
                }
                Button(action: {
                    selectedSpeed = averageSpeed
                    displayGlobe = false
                }, label: {
                    Text("Average Speed: \(Int(averageSpeed ?? 0)) MPH")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    selectedSpeed = maximumSpeed
                    displayGlobe = false
                }, label: {
                    Text("Maximum Speed: \(Int(maximumSpeed ?? 0)) MPH")
                        .bold()
                        .padding(.bottom, 5)
                })
                Button(action: {
                    displayGlobe = true
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
            
            if displayGlobe {
                Earth3DView()
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
    
    func calculatePercentageAroundGlobe(milesRun: Double) -> String {
        let earthCircumference = 24901.0  // Earth's circumference in miles
        let percentageRun = (milesRun / earthCircumference) * 100
        return String(format: "You have run %.2f%% of the Earth's circumference.", percentageRun)  // Format to 2 decimal places
    }
}

#Preview {
    RunningView()
}
