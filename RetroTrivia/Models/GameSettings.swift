//
//  GameSettings.swift
//  RetroTrivia
//

import Foundation

struct GameSettings {
    var timerEnabled: Bool
    var timerDuration: Int      // seconds per question
    var leaderboardMode: Bool   // 3-minute timed game, eligible for leaderboard
    var livesEnabled: Bool
    var startingLives: Int

    // Play mode: 2-minute timed challenge, no lives
    static let leaderboardDuration: Int = 120

    // Gauntlet mode: 3 lives, no game timer
    static let gauntletLives: Int = 3

    private static let timerEnabledKey = "game.settings.timerEnabled"
    private static let timerDurationKey = "game.settings.timerDuration"
    private static let leaderboardModeKey = "game.settings.leaderboardMode"
    private static let livesEnabledKey = "game.settings.livesEnabled"
    private static let startingLivesKey = "game.settings.startingLives"

    // Timer is fixed at 10 seconds per question
    static let fixedTimerDuration: Int = 10

    init(timerEnabled: Bool = false, timerDuration: Int = 10,
         leaderboardMode: Bool = false,
         livesEnabled: Bool = false, startingLives: Int = 3) {
        self.timerEnabled = timerEnabled
        self.timerDuration = Self.fixedTimerDuration  // Always use fixed duration
        self.leaderboardMode = leaderboardMode
        self.livesEnabled = livesEnabled
        self.startingLives = startingLives
    }

    static func load() -> GameSettings {
        let enabled = UserDefaults.standard.object(forKey: timerEnabledKey) as? Bool ?? false
        let leaderboardMode = UserDefaults.standard.object(forKey: leaderboardModeKey) as? Bool ?? false
        let livesEnabled = UserDefaults.standard.object(forKey: livesEnabledKey) as? Bool ?? false
        let startingLives = UserDefaults.standard.object(forKey: startingLivesKey) as? Int ?? 3
        return GameSettings(timerEnabled: enabled, timerDuration: fixedTimerDuration,
                            leaderboardMode: leaderboardMode,
                            livesEnabled: livesEnabled, startingLives: max(1, startingLives))
    }

    func save() {
        UserDefaults.standard.set(timerEnabled, forKey: Self.timerEnabledKey)
        UserDefaults.standard.set(timerDuration, forKey: Self.timerDurationKey)
        UserDefaults.standard.set(leaderboardMode, forKey: Self.leaderboardModeKey)
        UserDefaults.standard.set(livesEnabled, forKey: Self.livesEnabledKey)
        UserDefaults.standard.set(startingLives, forKey: Self.startingLivesKey)
    }
}
