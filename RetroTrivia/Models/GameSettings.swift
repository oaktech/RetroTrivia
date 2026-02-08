//
//  GameSettings.swift
//  RetroTrivia
//

import Foundation

struct GameSettings {
    var timerEnabled: Bool
    var timerDuration: Int      // seconds per question
    var gameTimerEnabled: Bool
    var gameTimerDuration: Int  // total game seconds
    var livesEnabled: Bool
    var startingLives: Int

    private static let timerEnabledKey = "game.settings.timerEnabled"
    private static let timerDurationKey = "game.settings.timerDuration"
    private static let gameTimerEnabledKey = "game.settings.gameTimerEnabled"
    private static let gameTimerDurationKey = "game.settings.gameTimerDuration"
    private static let livesEnabledKey = "game.settings.livesEnabled"
    private static let startingLivesKey = "game.settings.startingLives"

    init(timerEnabled: Bool = false, timerDuration: Int = 15,
         gameTimerEnabled: Bool = false, gameTimerDuration: Int = 180,
         livesEnabled: Bool = false, startingLives: Int = 3) {
        self.timerEnabled = timerEnabled
        self.timerDuration = timerDuration
        self.gameTimerEnabled = gameTimerEnabled
        self.gameTimerDuration = gameTimerDuration
        self.livesEnabled = livesEnabled
        self.startingLives = startingLives
    }

    static func load() -> GameSettings {
        let enabled = UserDefaults.standard.object(forKey: timerEnabledKey) as? Bool ?? false
        let duration = UserDefaults.standard.object(forKey: timerDurationKey) as? Int ?? 15
        let gameEnabled = UserDefaults.standard.object(forKey: gameTimerEnabledKey) as? Bool ?? false
        let gameDuration = UserDefaults.standard.object(forKey: gameTimerDurationKey) as? Int ?? 180
        let livesEnabled = UserDefaults.standard.object(forKey: livesEnabledKey) as? Bool ?? false
        let startingLives = UserDefaults.standard.object(forKey: startingLivesKey) as? Int ?? 3
        return GameSettings(timerEnabled: enabled, timerDuration: max(5, duration),
                            gameTimerEnabled: gameEnabled, gameTimerDuration: max(60, gameDuration),
                            livesEnabled: livesEnabled, startingLives: max(1, startingLives))
    }

    func save() {
        UserDefaults.standard.set(timerEnabled, forKey: Self.timerEnabledKey)
        UserDefaults.standard.set(timerDuration, forKey: Self.timerDurationKey)
        UserDefaults.standard.set(gameTimerEnabled, forKey: Self.gameTimerEnabledKey)
        UserDefaults.standard.set(gameTimerDuration, forKey: Self.gameTimerDurationKey)
        UserDefaults.standard.set(livesEnabled, forKey: Self.livesEnabledKey)
        UserDefaults.standard.set(startingLives, forKey: Self.startingLivesKey)
    }
}
