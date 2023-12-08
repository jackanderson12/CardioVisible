//
//  CardioVisibleApp.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI

@main
struct CardioVisibleApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                    }
                RunningView()
                    .tabItem {
                        Image(systemName: "figure.run.circle.fill")
                    }
            }
        }
    }
}
