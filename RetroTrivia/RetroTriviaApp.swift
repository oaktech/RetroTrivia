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
    @State private var audioManager = AudioManager.shared
    @State private var questionManager = QuestionManager()
    @State private var gameCenterManager = GameCenterManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(audioManager)
                .environment(questionManager)
                .environment(gameCenterManager)
                .onAppear {
                    gameCenterManager.authenticate()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Resume music when app becomes active
                audioManager.resumeBackgroundMusic()
            case .background:
                // Pause music when app goes to background
                audioManager.pauseBackgroundMusic()
                print("App entering background - state persisted")
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    init() {
        // Start menu music when app launches
        AudioManager.shared.playMenuMusic()
    }
}
