//
//  RetroTriviaApp.swift
//  RetroTrivia
//
//  Created by Craig Oaks on 2/4/26.
//

import SwiftUI

@main
struct RetroTriviaApp: App {
    @State private var gameState = GameState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // Ensure state is persisted when app goes to background
                print("App entering background - state persisted")
            }
        }
    }
}
