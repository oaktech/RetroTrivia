//
//  DailyChallengeManager.swift
//  RetroTrivia
//

import Foundation
import Observation

@MainActor
@Observable
class DailyChallengeManager {
    static let shared = DailyChallengeManager()

    // MARK: - UserDefaults Keys

    private static let lastCompletedDateKey = "dailyChallenge.lastCompletedDate"
    private static let currentStreakKey = "dailyChallenge.currentStreak"
    private static let bestStreakKey = "dailyChallenge.bestStreak"
    private static let totalCompletedKey = "dailyChallenge.totalCompleted"
    private static let lastScoreKey = "dailyChallenge.lastScore"
    private static let bestScoreKey = "dailyChallenge.bestScore"

    // MARK: - Daily Challenge Config

    /// Number of questions in each daily challenge
    static let questionCount = 10

    // MARK: - Observable State

    private(set) var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: Self.currentStreakKey) }
    }

    private(set) var bestStreak: Int {
        didSet { UserDefaults.standard.set(bestStreak, forKey: Self.bestStreakKey) }
    }

    private(set) var totalCompleted: Int {
        didSet { UserDefaults.standard.set(totalCompleted, forKey: Self.totalCompletedKey) }
    }

    private(set) var lastScore: Int {
        didSet { UserDefaults.standard.set(lastScore, forKey: Self.lastScoreKey) }
    }

    private(set) var bestScore: Int {
        didSet { UserDefaults.standard.set(bestScore, forKey: Self.bestScoreKey) }
    }

    /// The date string (yyyy-MM-dd) of the last completed daily challenge
    private var lastCompletedDateString: String? {
        didSet { UserDefaults.standard.set(lastCompletedDateString, forKey: Self.lastCompletedDateKey) }
    }

    // MARK: - Computed State

    var isTodayCompleted: Bool {
        lastCompletedDateString == todayDateString
    }

    var isStreakActive: Bool {
        guard let lastDate = lastCompletedDateString else { return false }
        return lastDate == todayDateString || lastDate == yesterdayDateString
    }

    var streakExpiresEndOfDay: Bool {
        lastCompletedDateString == yesterdayDateString
    }

    // MARK: - Init

    private init() {
        self.currentStreak = UserDefaults.standard.integer(forKey: Self.currentStreakKey)
        self.bestStreak = UserDefaults.standard.integer(forKey: Self.bestStreakKey)
        self.totalCompleted = UserDefaults.standard.integer(forKey: Self.totalCompletedKey)
        self.lastScore = UserDefaults.standard.integer(forKey: Self.lastScoreKey)
        self.bestScore = UserDefaults.standard.integer(forKey: Self.bestScoreKey)
        self.lastCompletedDateString = UserDefaults.standard.string(forKey: Self.lastCompletedDateKey)

        // Check if streak has expired (missed more than one day)
        validateStreak()
    }

    // MARK: - Public API

    /// Record completion of today's daily challenge.
    func recordCompletion(score: Int) {
        let wasStreakActive = isStreakActive

        lastScore = score
        if score > bestScore {
            bestScore = score
        }

        totalCompleted += 1

        if wasStreakActive || lastCompletedDateString == nil {
            // Continue or start streak
            if lastCompletedDateString != todayDateString {
                currentStreak += 1
            }
        } else {
            // Streak was broken — start fresh
            currentStreak = 1
        }

        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }

        lastCompletedDateString = todayDateString
    }

    // MARK: - Private

    private func validateStreak() {
        guard let lastDate = lastCompletedDateString else {
            currentStreak = 0
            return
        }

        // If last completed date is neither today nor yesterday, streak is broken
        if lastDate != todayDateString && lastDate != yesterdayDateString {
            currentStreak = 0
        }
    }

    private var todayDateString: String {
        Self.dateFormatter.string(from: Date())
    }

    private var yesterdayDateString: String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return Self.dateFormatter.string(from: yesterday)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    // MARK: - Debug

    #if DEBUG
    func resetAll() {
        currentStreak = 0
        bestStreak = 0
        totalCompleted = 0
        lastScore = 0
        bestScore = 0
        lastCompletedDateString = nil
    }

    /// Set arbitrary state for unit testing date-dependent logic.
    func setTestState(lastCompletedDate: String?, currentStreak: Int) {
        lastCompletedDateString = lastCompletedDate
        self.currentStreak = currentStreak
    }

    /// Expose date formatting for test assertions.
    static func formatDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// Re-run streak validation (normally only called at init).
    func debugValidateStreak() {
        validateStreak()
    }
    #endif
}
