//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject private var healthStore = HealthStore()
    
    var body: some View {
        VStack {
            if let heartRateData = healthStore.heartRateReading {
                if let restingRate = healthStore.heartRateReading?.resting {
                    HeartBeat3DView(rate: restingRate)
                        .padding()
                } else {
                    Text("Loading heart rate data...")
                }
                Text("Resting Heart Rate This Week: \(Int(heartRateData.resting ?? 0)) BPM")
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


struct HeartbeatView: View {
    var rate: Double // Resting heart rate in beats per minute
    private var animationDuration: Double {
        // Calculate the duration of one beat based on the heart rate
        60.0 / rate
    }
    
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "heart.fill") // Using a system image, you can replace it with your own
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundColor(.red)
            .scaleEffect(animate ? 1.1 : 1.0) // Scale up slightly when animated
            .onAppear {
                withAnimation(Animation.easeInOut(duration: animationDuration).repeatForever(autoreverses: true)) {
                    animate = true
                }
            }
    }
}

#Preview {
    ContentView()
}
