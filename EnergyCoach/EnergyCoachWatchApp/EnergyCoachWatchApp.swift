//
//  EnergyCoachWatchApp.swift
//  EnergyCoachWatchApp
//
//  Created by Codex on 14/07/2026.
//

import SwiftUI

@main
struct EnergyCoachWatchApp: App {
    @StateObject private var model = WatchEnergyModel()

    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(model)
        }
    }
}
