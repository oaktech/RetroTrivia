//
//  RetroTriviaApp.swift
//  RetroTrivia
//
//  Created by Craig Oaks on 2/4/26.
//

import SwiftUI
import CoreText

@main
struct RetroTriviaApp: App {
    @State private var gameState = GameState()
    @State private var audioManager = AudioManager.shared
    @State private var questionManager = QuestionManager()
    @State private var gameCenterManager = GameCenterManager.shared
    @State private var badgeManager = BadgeManager.shared
    @State private var notificationManager = NotificationManager.shared
    @State private var dailyChallengeManager = DailyChallengeManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(gameState)
                .environment(audioManager)
                .environment(questionManager)
                .environment(gameCenterManager)
                .environment(badgeManager)
                .onAppear {
                    gameCenterManager.authenticate()
                    Task {
                        await notificationManager.refreshAuthorizationStatus()
                    }
                    // Cancel lapsed-user reminders since the user just opened the app
                    notificationManager.cancelLapsedUserReminders()
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Resume music when app becomes active
                audioManager.resumeBackgroundMusic()
                // Cancel lapsed-user reminders on foreground
                notificationManager.cancelLapsedUserReminders()
                // Refresh notification authorization status
                Task {
                    await notificationManager.refreshAuthorizationStatus()
                }
            case .background:
                // Pause music when app goes to background
                audioManager.pauseBackgroundMusic()
                print("App entering background - state persisted")
                // Schedule engagement notifications when going to background
                notificationManager.scheduleDailyChallengeReminder()
                notificationManager.scheduleLapsedUserReminders(highScore: gameState.highScorePosition)
                if dailyChallengeManager.isStreakActive && !dailyChallengeManager.isTodayCompleted {
                    notificationManager.scheduleStreakReminder(
                        currentStreak: dailyChallengeManager.currentStreak
                    )
                }
                notificationManager.scheduleWeeklyLeaderboardReminder()
            case .inactive:
                break
            @unknown default:
                break
            }
        }
    }

    init() {
        registerFonts()
        AudioManager.shared.playMenuMusic()
    }

    private func registerFonts() {
        ["PressStart2P-Regular", "Orbitron-Regular", "Orbitron-Bold"].forEach { name in
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { return }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
