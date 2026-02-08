//
//  GameSettings.swift
//  RetroTrivia
//

import Foundation

struct GameSettings {
    var timerEnabled: Bool
    var timerDuration: Int  // seconds

    private static let timerEnabledKey = "game.settings.timerEnabled"
    private static let timerDurationKey = "game.settings.timerDuration"

    init(timerEnabled: Bool = false, timerDuration: Int = 15) {
        self.timerEnabled = timerEnabled
        self.timerDuration = timerDuration
    }

    static func load() -> GameSettings {
        let enabled = UserDefaults.standard.object(forKey: timerEnabledKey) as? Bool ?? false
        let duration = UserDefaults.standard.object(forKey: timerDurationKey) as? Int ?? 15
        return GameSettings(timerEnabled: enabled, timerDuration: max(5, duration))
    }

    func save() {
        UserDefaults.standard.set(timerEnabled, forKey: Self.timerEnabledKey)
        UserDefaults.standard.set(timerDuration, forKey: Self.timerDurationKey)
    }
}
