//
//  BadgeManager.swift
//  RetroTrivia
//

import Foundation
import Observation

@MainActor
@Observable
class BadgeManager {
    static let shared = BadgeManager()

    private static let unlockedIDsKey = "badge.unlockedIDs"
    private static let totalGamesKey  = "badge.totalGamesPlayed"

    private(set) var unlockedIDs: Set<String> {
        didSet { save() }
    }

    private(set) var totalGamesPlayed: Int {
        didSet { save() }
    }

    private init() {
        let savedIDs = UserDefaults.standard.stringArray(forKey: Self.unlockedIDsKey) ?? []
        self.unlockedIDs = Set(savedIDs)
        self.totalGamesPlayed = UserDefaults.standard.integer(forKey: Self.totalGamesKey)
    }

    // MARK: - Public API

    func isUnlocked(_ id: String) -> Bool {
        unlockedIDs.contains(id)
    }

    /// Call at the start of each game to increment the play count.
    func recordGameStarted() {
        totalGamesPlayed += 1
    }

    /// Evaluate all conditions and return newly-unlocked badges.
    /// - Parameters:
    ///   - position:          Current map position (0-25).
    ///   - streak:            Consecutive correct answers this game.
    ///   - livesRemaining:    Lives left (only meaningful in Gauntlet).
    ///   - isLeaderboardMode: True when playing in ranked/Play mode.
    ///   - isGameOver:        True when called at the game-over moment.
    @discardableResult
    func checkBadges(
        position: Int,
        streak: Int,
        livesRemaining: Int,
        isLeaderboardMode: Bool,
        isGameOver: Bool,
        difficulty: Difficulty = .any
    ) -> [Badge] {
        var newly: [Badge] = []

        func tryUnlock(_ id: String) {
            guard !unlockedIDs.contains(id), let badge = Badge.find(id: id) else { return }
            unlockedIDs.insert(id)
            newly.append(badge)
        }

        // --- Progress badges ---
        if position >= 5  { tryUnlock("level_5") }
        if position >= 10 { tryUnlock("level_10") }
        if position >= 15 { tryUnlock("level_15") }
        if position >= 20 { tryUnlock("level_20") }
        if position >= 25 { tryUnlock("level_25") }

        // --- Streak badges ---
        if streak >= 5  { tryUnlock("streak_5") }
        if streak >= 10 { tryUnlock("streak_10") }

        // --- Dedication badges (on game-start, totalGamesPlayed is already incremented) ---
        if totalGamesPlayed >= 10 { tryUnlock("games_10") }
        if totalGamesPlayed >= 25 { tryUnlock("games_25") }

        // --- Mode badges (only on game-over) ---
        if isGameOver {
            if isLeaderboardMode {
                tryUnlock("first_play")
            } else {
                tryUnlock("first_gauntlet")
                if livesRemaining >= 3 { tryUnlock("gauntlet_flawless") }
                if livesRemaining == 1 { tryUnlock("gauntlet_survivor") }
                if difficulty == .hard  { tryUnlock("gauntlet_hard") }
            }
        }

        return newly
    }

    // MARK: - Persistence

    private func save() {
        UserDefaults.standard.set(Array(unlockedIDs), forKey: Self.unlockedIDsKey)
        UserDefaults.standard.set(totalGamesPlayed, forKey: Self.totalGamesKey)
    }

    // MARK: - Debug Helpers

    #if DEBUG
    @discardableResult
    func forceUnlock(_ id: String) -> [Badge] {
        guard !unlockedIDs.contains(id), let badge = Badge.find(id: id) else { return [] }
        unlockedIDs.insert(id)
        return [badge]
    }

    func resetAll() {
        unlockedIDs = []
        totalGamesPlayed = 0
    }
    #endif
}
