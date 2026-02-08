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

    private static let timerEnabledKey = "game.settings.timerEnabled"
    private static let timerDurationKey = "game.settings.timerDuration"
    private static let gameTimerEnabledKey = "game.settings.gameTimerEnabled"
    private static let gameTimerDurationKey = "game.settings.gameTimerDuration"

    init(timerEnabled: Bool = false, timerDuration: Int = 15,
         gameTimerEnabled: Bool = false, gameTimerDuration: Int = 180) {
        self.timerEnabled = timerEnabled
        self.timerDuration = timerDuration
        self.gameTimerEnabled = gameTimerEnabled
        self.gameTimerDuration = gameTimerDuration
    }

    static func load() -> GameSettings {
        let enabled = UserDefaults.standard.object(forKey: timerEnabledKey) as? Bool ?? false
        let duration = UserDefaults.standard.object(forKey: timerDurationKey) as? Int ?? 15
        let gameEnabled = UserDefaults.standard.object(forKey: gameTimerEnabledKey) as? Bool ?? false
        let gameDuration = UserDefaults.standard.object(forKey: gameTimerDurationKey) as? Int ?? 180
        return GameSettings(timerEnabled: enabled, timerDuration: max(5, duration),
                            gameTimerEnabled: gameEnabled, gameTimerDuration: max(60, gameDuration))
    }

    func save() {
        UserDefaults.standard.set(timerEnabled, forKey: Self.timerEnabledKey)
        UserDefaults.standard.set(timerDuration, forKey: Self.timerDurationKey)
        UserDefaults.standard.set(gameTimerEnabled, forKey: Self.gameTimerEnabledKey)
        UserDefaults.standard.set(gameTimerDuration, forKey: Self.gameTimerDurationKey)
    }
}
