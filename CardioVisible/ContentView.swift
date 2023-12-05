//
//  ContentView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

struct ContentView: View {
    
    @State private var healthStore = HealthStore()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .task {
            await healthStore.requestAuthorization()
        }
    }
    
}

#Preview {
    ContentView()
}
