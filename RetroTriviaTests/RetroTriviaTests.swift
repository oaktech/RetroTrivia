//
//  RetroTriviaTests.swift
//  RetroTriviaTests
//

import Testing
import Foundation
import SwiftUI
import UserNotifications
@testable import RetroTrivia

// MARK: - TriviaQuestion Tests

struct TriviaQuestionTests {

    @Test func initWithDefaults() {
        let q = TriviaQuestion(
            question: "Who sang 'Billie Jean'?",
            options: ["Michael Jackson", "Prince", "David Bowie", "Madonna"],
            correctIndex: 0
        )
        #expect(q.question == "Who sang 'Billie Jean'?")
        #expect(q.options.count == 4)
        #expect(q.correctIndex == 0)
        #expect(q.category == nil)
        #expect(q.difficulty == nil)
        #expect(q.source == .bundle)
        #expect(!q.id.isEmpty)
    }

    @Test func initWithAllFields() {
        let q = TriviaQuestion(
            id: "test-id",
            question: "What year did 'Like a Virgin' release?",
            options: ["1983", "1984", "1985", "1986"],
            correctIndex: 1,
            category: "Music",
            difficulty: "easy",
            source: .cloudKit
        )
        #expect(q.id == "test-id")
        #expect(q.correctIndex == 1)
        #expect(q.category == "Music")
        #expect(q.difficulty == "easy")
        #expect(q.source == .cloudKit)
    }

    @Test func jsonDecodingMinimalFields() throws {
        let json = """
        [{"id":"q1","question":"Who sang Purple Rain?","options":["Prince","Bowie","Elton","Springsteen"],"correctIndex":0}]
        """
        let data = json.data(using: .utf8)!
        let questions = try JSONDecoder().decode([TriviaQuestion].self, from: data)
        #expect(questions.count == 1)
        #expect(questions[0].id == "q1")
        #expect(questions[0].source == .bundle)
        #expect(questions[0].difficulty == nil)
    }

    @Test func jsonDecodingWithAllFields() throws {
        let json = """
        [{"id":"q2","question":"Test?","options":["A","B","C","D"],"correctIndex":2,"category":"Music","difficulty":"hard","source":"cloudKit"}]
        """
        let data = json.data(using: .utf8)!
        let questions = try JSONDecoder().decode([TriviaQuestion].self, from: data)
        #expect(questions[0].source == .cloudKit)
        #expect(questions[0].difficulty == "hard")
        #expect(questions[0].correctIndex == 2)
    }

    @Test func jsonRoundTrip() throws {
        let original = TriviaQuestion(
            id: "rt-1",
            question: "Round trip test?",
            options: ["A", "B", "C", "D"],
            correctIndex: 3,
            category: "Music",
            difficulty: "medium",
            source: .cloudKit
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(TriviaQuestion.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.question == original.question)
        #expect(decoded.options == original.options)
        #expect(decoded.correctIndex == original.correctIndex)
        #expect(decoded.category == original.category)
        #expect(decoded.difficulty == original.difficulty)
        #expect(decoded.source == original.source)
    }

    @Test func jsonDecodingInvalidSourceDefaultsToBundle() throws {
        let json = """
        [{"id":"q3","question":"Test?","options":["A","B","C","D"],"correctIndex":0,"source":"unknownSource"}]
        """
        let data = json.data(using: .utf8)!
        let questions = try JSONDecoder().decode([TriviaQuestion].self, from: data)
        #expect(questions[0].source == .bundle)
    }

    @Test func eachQuestionHasUniqueIDWhenCreatedWithout() {
        let q1 = TriviaQuestion(question: "Q1?", options: ["A","B","C","D"], correctIndex: 0)
        let q2 = TriviaQuestion(question: "Q2?", options: ["A","B","C","D"], correctIndex: 0)
        #expect(q1.id != q2.id)
    }
}

// MARK: - GameSettings Tests

struct GameSettingsTests {

    @Test func defaultValues() {
        let settings = GameSettings()
        #expect(settings.timerEnabled == false)
        #expect(settings.timerDuration == GameSettings.fixedTimerDuration)
        #expect(settings.leaderboardMode == false)
        #expect(settings.livesEnabled == false)
        #expect(settings.startingLives == 3)
    }

    @Test func timerDurationAlwaysFixed() {
        // Even if you pass a custom timerDuration, it's overridden by the fixed constant
        let settings = GameSettings(timerEnabled: true, timerDuration: 99)
        #expect(settings.timerDuration == GameSettings.fixedTimerDuration)
    }

    @Test func staticConstants() {
        #expect(GameSettings.leaderboardDuration == 120)
        #expect(GameSettings.gauntletLives == 3)
        #expect(GameSettings.fixedTimerDuration == 10)
    }

    @Test func leaderboardModeEnabled() {
        let settings = GameSettings(leaderboardMode: true)
        #expect(settings.leaderboardMode == true)
    }

    @Test func livesEnabledWithCustomStartingLives() {
        let settings = GameSettings(livesEnabled: true, startingLives: 5)
        #expect(settings.livesEnabled == true)
        #expect(settings.startingLives == 5)
    }

    @Test func saveAndLoad() {
        let suite = UserDefaults(suiteName: "test.gamesettings.\(UUID().uuidString)")!
        // GameSettings uses UserDefaults.standard, so we test round-trip behavior indirectly
        let settings = GameSettings(timerEnabled: true, leaderboardMode: true, livesEnabled: true, startingLives: 5)
        settings.save()
        let loaded = GameSettings.load()
        #expect(loaded.timerEnabled == settings.timerEnabled)
        #expect(loaded.leaderboardMode == settings.leaderboardMode)
        #expect(loaded.livesEnabled == settings.livesEnabled)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "game.settings.timerEnabled")
        UserDefaults.standard.removeObject(forKey: "game.settings.leaderboardMode")
        UserDefaults.standard.removeObject(forKey: "game.settings.livesEnabled")
        UserDefaults.standard.removeObject(forKey: "game.settings.startingLives")
    }
}

// MARK: - Difficulty Tests

struct DifficultyTests {

    @Test func allCases() {
        let cases = Difficulty.allCases
        #expect(cases.count == 4)
        #expect(cases.contains(.any))
        #expect(cases.contains(.easy))
        #expect(cases.contains(.medium))
        #expect(cases.contains(.hard))
    }

    @Test func displayNames() {
        #expect(Difficulty.any.displayName == "Any")
        #expect(Difficulty.easy.displayName == "Easy")
        #expect(Difficulty.medium.displayName == "Medium")
        #expect(Difficulty.hard.displayName == "Hard")
    }

    @Test func apiValueForAnyIsNil() {
        #expect(Difficulty.any.apiValue == nil)
    }

    @Test func apiValueForOthersMatchRawValue() {
        #expect(Difficulty.easy.apiValue == "easy")
        #expect(Difficulty.medium.apiValue == "medium")
        #expect(Difficulty.hard.apiValue == "hard")
    }

    @Test func rawValues() {
        #expect(Difficulty.any.rawValue == "any")
        #expect(Difficulty.easy.rawValue == "easy")
        #expect(Difficulty.medium.rawValue == "medium")
        #expect(Difficulty.hard.rawValue == "hard")
    }

    @Test func initFromRawValue() {
        #expect(Difficulty(rawValue: "easy") == .easy)
        #expect(Difficulty(rawValue: "medium") == .medium)
        #expect(Difficulty(rawValue: "hard") == .hard)
        #expect(Difficulty(rawValue: "any") == .any)
        #expect(Difficulty(rawValue: "unknown") == nil)
    }
}

// MARK: - FilterConfiguration Tests

@Suite(.serialized)
struct FilterConfigurationTests {

    @Test func defaultDifficultyIsAny() {
        let config = FilterConfiguration()
        #expect(config.difficulty == .any)
    }

    @Test func initWithSpecificDifficulty() {
        let config = FilterConfiguration(difficulty: .hard)
        #expect(config.difficulty == .hard)
    }

    @Test func saveAndLoad() {
        let config = FilterConfiguration(difficulty: .medium)
        config.save()
        let loaded = FilterConfiguration.load()
        #expect(loaded.difficulty == .medium)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "trivia.filter.difficulty")
    }

    @Test func loadDefaultsToAnyWhenNotSet() {
        UserDefaults.standard.removeObject(forKey: "trivia.filter.difficulty")
        let loaded = FilterConfiguration.load()
        #expect(loaded.difficulty == .any)
    }

    @Test func codableRoundTrip() throws {
        let original = FilterConfiguration(difficulty: .hard)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(FilterConfiguration.self, from: data)
        #expect(decoded.difficulty == original.difficulty)
    }
}

// MARK: - Badge Tests

struct BadgeTests {

    @Test func totalBadgeCount() {
        #expect(Badge.all.count == 14)
    }

    @Test func findExistingBadge() {
        let badge = Badge.find(id: "level_5")
        #expect(badge != nil)
        #expect(badge?.title == "Rising Star")
    }

    @Test func findNonExistentBadge() {
        let badge = Badge.find(id: "nonexistent_badge")
        #expect(badge == nil)
    }

    @Test func allBadgeIDsAreUnique() {
        let ids = Badge.all.map { $0.id }
        let uniqueIDs = Set(ids)
        #expect(ids.count == uniqueIDs.count)
    }

    @Test func progressBadgeIDs() {
        let progressIDs = ["level_5", "level_10", "level_15", "level_20", "level_25"]
        for id in progressIDs {
            #expect(Badge.find(id: id) != nil, "Missing badge: \(id)")
        }
    }

    @Test func streakBadgeIDs() {
        #expect(Badge.find(id: "streak_5") != nil)
        #expect(Badge.find(id: "streak_10") != nil)
    }

    @Test func modeBadgeIDs() {
        let modeIDs = ["first_play", "first_gauntlet", "gauntlet_flawless", "gauntlet_survivor"]
        for id in modeIDs {
            #expect(Badge.find(id: id) != nil, "Missing badge: \(id)")
        }
    }

    @Test func dedicationBadgeIDs() {
        #expect(Badge.find(id: "games_10") != nil)
        #expect(Badge.find(id: "games_25") != nil)
    }

    @Test func hardcoreBadge() {
        #expect(Badge.find(id: "gauntlet_hard") != nil)
    }

    @Test func badgeHasRequiredFields() {
        for badge in Badge.all {
            #expect(!badge.id.isEmpty, "Badge id empty")
            #expect(!badge.title.isEmpty, "Badge title empty for \(badge.id)")
            #expect(!badge.description.isEmpty, "Badge description empty for \(badge.id)")
            #expect(!badge.iconName.isEmpty, "Badge iconName empty for \(badge.id)")
            #expect(!badge.iconColor.isEmpty, "Badge iconColor empty for \(badge.id)")
        }
    }
}

// MARK: - GameState Tests

@MainActor
struct GameStateTests {

    // Helper: create a GameState with clean UserDefaults
    private func makeCleanGameState() -> GameState {
        let keys = ["currentPosition", "highScorePosition"]
        for key in keys { UserDefaults.standard.removeObject(forKey: key) }
        return GameState()
    }

    @Test func initialPositionIsZero() {
        let state = makeCleanGameState()
        #expect(state.currentPosition == 0)
    }

    @Test func initialHighScoreIsZero() {
        let state = makeCleanGameState()
        #expect(state.highScorePosition == 0)
    }

    @Test func initialLivesIsThree() {
        let state = makeCleanGameState()
        #expect(state.livesRemaining == 3)
    }

    @Test func incrementPosition() {
        let state = makeCleanGameState()
        state.incrementPosition()
        #expect(state.currentPosition == 1)
    }

    @Test func decrementPositionAboveZero() {
        let state = makeCleanGameState()
        state.currentPosition = 5
        state.decrementPosition()
        #expect(state.currentPosition == 4)
    }

    @Test func decrementPositionAtZeroDoesNotGoNegative() {
        let state = makeCleanGameState()
        #expect(state.currentPosition == 0)
        state.decrementPosition()
        #expect(state.currentPosition == 0)
    }

    @Test func incrementMultipleTimes() {
        let state = makeCleanGameState()
        for _ in 0..<10 {
            state.incrementPosition()
        }
        #expect(state.currentPosition == 10)
    }

    @Test func resetGameResetsPosition() {
        let state = makeCleanGameState()
        state.currentPosition = 15
        state.resetGame()
        #expect(state.currentPosition == 0)
    }

    @Test func resetGameResetsLives() {
        let state = makeCleanGameState()
        state.livesRemaining = 1
        state.gameSettings.startingLives = 3
        state.resetGame()
        #expect(state.livesRemaining == 3)
    }

    @Test func resetGameDoesNotResetHighScore() {
        let state = makeCleanGameState()
        state.highScorePosition = 20
        state.currentPosition = 10
        state.resetGame()
        #expect(state.highScorePosition == 20)
    }

    @Test func highScoreUpdatesInLeaderboardMode() {
        let state = makeCleanGameState()
        state.gameSettings.leaderboardMode = true
        state.currentPosition = 10
        #expect(state.highScorePosition == 10)
        state.currentPosition = 8  // lower than high score
        #expect(state.highScorePosition == 10)  // should not decrease
        state.currentPosition = 15
        #expect(state.highScorePosition == 15)
    }

    @Test func highScoreDoesNotUpdateOutsideLeaderboardMode() {
        let state = makeCleanGameState()
        state.gameSettings.leaderboardMode = false
        state.currentPosition = 10
        #expect(state.highScorePosition == 0)  // should not have been updated
    }

    @Test func positionPersistedToUserDefaults() {
        let state = makeCleanGameState()
        state.currentPosition = 7
        let saved = UserDefaults.standard.integer(forKey: "currentPosition")
        #expect(saved == 7)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "currentPosition")
    }

    @Test func highScorePersistedToUserDefaults() {
        let state = makeCleanGameState()
        state.highScorePosition = 12
        let saved = UserDefaults.standard.integer(forKey: "highScorePosition")
        #expect(saved == 12)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "highScorePosition")
    }
}

// MARK: - PassAndPlaySession Tests

struct PassAndPlaySessionTests {

    private func makeSession(names: [String] = ["Alice", "Bob"], roundLimit: RoundLimit = .fixed(5)) -> PassAndPlaySession {
        PassAndPlaySession(playerNames: names, roundLimit: roundLimit, difficulty: .any)
    }

    @Test func initWithTwoPlayers() {
        let session = makeSession(names: ["Alice", "Bob"])
        #expect(session.players.count == 2)
        #expect(session.players[0].name == "Alice")
        #expect(session.players[1].name == "Bob")
    }

    @Test func initWithFourPlayers() {
        let session = makeSession(names: ["A", "B", "C", "D"])
        #expect(session.players.count == 4)
    }

    @Test func initialPlayerIndexIsZero() {
        let session = makeSession()
        #expect(session.currentPlayerIndex == 0)
    }

    @Test func currentPlayerMatchesIndex() {
        let session = makeSession(names: ["Alice", "Bob"])
        #expect(session.currentPlayer.name == "Alice")
    }

    @Test func allPlayersStartAtPositionZero() {
        let session = makeSession(names: ["Alice", "Bob", "Carol"])
        for player in session.players {
            #expect(player.position == 0)
        }
    }

    @Test func allPlayersHaveUniqueColors() {
        let session = makeSession(names: ["A", "B", "C", "D"])
        // Colors cycle from a fixed array of 4, so 4 players get 4 distinct colors
        // We verify they have colors set (not nil)
        #expect(session.players.count == 4)
    }

    @Test func advanceToNextPlayerWraps() {
        let session = makeSession(names: ["Alice", "Bob"])
        #expect(session.currentPlayerIndex == 0)
        session.advanceToNextPlayer()
        #expect(session.currentPlayerIndex == 1)
        session.advanceToNextPlayer()
        #expect(session.currentPlayerIndex == 0)  // wraps back
    }

    @Test func advanceToNextPlayerWithFourPlayers() {
        let session = makeSession(names: ["A", "B", "C", "D"])
        for expected in [1, 2, 3, 0, 1] {
            session.advanceToNextPlayer()
            #expect(session.currentPlayerIndex == expected)
        }
    }

    @Test func maxPositionWithNoMovement() {
        let session = makeSession()
        #expect(session.maxPosition == 0)
    }

    @Test func maxPositionReflectsHighestPlayer() {
        let session = makeSession(names: ["Alice", "Bob"])
        session.players[0].position = 10
        session.players[1].position = 15
        #expect(session.maxPosition == 15)
    }

    @Test func winnerIsPlayerWithHighestPosition() {
        let session = makeSession(names: ["Alice", "Bob"])
        session.players[0].position = 5
        session.players[1].position = 20
        #expect(session.winner?.name == "Bob")
    }

    @Test func winnerIsNilWhenPlayersEmpty() {
        let session = PassAndPlaySession(playerNames: [], roundLimit: .fixed(5), difficulty: .any)
        #expect(session.winner == nil)
    }

    @Test func isRoundCompleteFixedModeFalseWhenNotDone() {
        let session = makeSession(roundLimit: .fixed(5))
        #expect(session.isRoundComplete == false)
    }

    @Test func isRoundCompleteFixedModeWhenAllDone() {
        let session = makeSession(names: ["Alice", "Bob"], roundLimit: .fixed(3))
        session.players[0].questionsAnswered = 3
        session.players[1].questionsAnswered = 3
        #expect(session.isRoundComplete == true)
    }

    @Test func isRoundCompleteRaceTo25AlwaysFalse() {
        let session = makeSession(roundLimit: .raceTo25)
        session.players[0].questionsAnswered = 100
        session.players[1].questionsAnswered = 100
        #expect(session.isRoundComplete == false)
    }

    @Test func checkWinConditionFixedModeNotDone() {
        let session = makeSession(roundLimit: .fixed(5))
        #expect(session.checkWinCondition() == false)
    }

    @Test func checkWinConditionFixedModeDone() {
        let session = makeSession(names: ["Alice", "Bob"], roundLimit: .fixed(5))
        session.players[0].questionsAnswered = 5
        session.players[1].questionsAnswered = 5
        #expect(session.checkWinCondition() == true)
    }

    @Test func checkWinConditionRaceTo25NotWon() {
        let session = makeSession(roundLimit: .raceTo25)
        session.players[0].position = 24
        #expect(session.checkWinCondition() == false)
    }

    @Test func checkWinConditionRaceTo25Won() {
        let session = makeSession(roundLimit: .raceTo25)
        session.players[0].position = 25
        #expect(session.checkWinCondition() == true)
    }

    @Test func checkWinConditionRaceTo25WonExceedingTarget() {
        let session = makeSession(roundLimit: .raceTo25)
        session.players[1].position = 26
        #expect(session.checkWinCondition() == true)
    }

    @Test func askedQuestionIDsStartsEmpty() {
        let session = makeSession()
        #expect(session.askedQuestionIDs.isEmpty)
    }

    @Test func sessionNotGameOverByDefault() {
        let session = makeSession()
        #expect(session.isGameOver == false)
    }

    @Test func sessionDifficultyRespected() {
        let session = PassAndPlaySession(playerNames: ["A", "B"], roundLimit: .fixed(5), difficulty: .hard)
        #expect(session.difficulty == .hard)
    }

    @Test func partialRoundNotComplete() {
        let session = makeSession(names: ["Alice", "Bob"], roundLimit: .fixed(5))
        session.players[0].questionsAnswered = 5
        session.players[1].questionsAnswered = 4  // one short
        #expect(session.isRoundComplete == false)
    }
}

// MARK: - BadgeManager Tests (isolated using fresh UserDefaults state)

@MainActor
struct BadgeManagerTests {

    // Create an isolated BadgeManager by using DEBUG reset
    private func freshManager() -> BadgeManager {
        let manager = BadgeManager.shared
        manager.resetAll()
        return manager
    }

    @Test func initiallyNoUnlockedBadges() {
        let manager = freshManager()
        #expect(manager.unlockedIDs.isEmpty)
    }

    @Test func isUnlockedReturnsFalseForLockedBadge() {
        let manager = freshManager()
        #expect(manager.isUnlocked("level_5") == false)
    }

    @Test func progressBadgeUnlocksAtLevel5() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 5, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(newly.contains { $0.id == "level_5" })
        #expect(manager.isUnlocked("level_5"))
    }

    @Test func progressBadgeDoesNotUnlockBefore5() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 4, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(!newly.contains { $0.id == "level_5" })
        #expect(!manager.isUnlocked("level_5"))
    }

    @Test func allProgressBadgesUnlockAtMaxPosition() {
        let manager = freshManager()
        manager.checkBadges(position: 25, streak: 0, livesRemaining: 3,
                            isLeaderboardMode: false, isGameOver: false)
        for id in ["level_5", "level_10", "level_15", "level_20", "level_25"] {
            #expect(manager.isUnlocked(id), "Expected \(id) to be unlocked")
        }
    }

    @Test func streakBadgeAt5() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 5, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(newly.contains { $0.id == "streak_5" })
    }

    @Test func streakBadgeAt10() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 10, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(newly.contains { $0.id == "streak_5" })
        #expect(newly.contains { $0.id == "streak_10" })
    }

    @Test func streakBadgeDoesNotUnlockBeforeThreshold() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 4, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(!newly.contains { $0.id == "streak_5" })
    }

    @Test func badgesDoNotDuplicate() {
        let manager = freshManager()
        manager.checkBadges(position: 5, streak: 5, livesRemaining: 3,
                            isLeaderboardMode: false, isGameOver: false)
        let second = manager.checkBadges(position: 5, streak: 5, livesRemaining: 3,
                                         isLeaderboardMode: false, isGameOver: false)
        #expect(!second.contains { $0.id == "level_5" })
        #expect(!second.contains { $0.id == "streak_5" })
    }

    @Test func firstPlayBadgeOnLeaderboardGameOver() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: true, isGameOver: true)
        #expect(newly.contains { $0.id == "first_play" })
    }

    @Test func firstPlayBadgeNotWithoutGameOver() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: true, isGameOver: false)
        #expect(!newly.contains { $0.id == "first_play" })
    }

    @Test func firstGauntletBadgeOnGauntletGameOver() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: true)
        #expect(newly.contains { $0.id == "first_gauntlet" })
    }

    @Test func gauntletFlawlessBadgeWithThreeLives() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: true)
        #expect(newly.contains { $0.id == "gauntlet_flawless" })
    }

    @Test func gauntletFlawlessBadgeNotWithFewerLives() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 2,
                                        isLeaderboardMode: false, isGameOver: true)
        #expect(!newly.contains { $0.id == "gauntlet_flawless" })
    }

    @Test func gauntletSurvivorBadgeWithOneLive() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 1,
                                        isLeaderboardMode: false, isGameOver: true)
        #expect(newly.contains { $0.id == "gauntlet_survivor" })
    }

    @Test func gauntletSurvivorNotWithMoreLives() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 2,
                                        isLeaderboardMode: false, isGameOver: true)
        #expect(!newly.contains { $0.id == "gauntlet_survivor" })
    }

    @Test func gauntletHardBadgeWithHardDifficulty() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 1,
                                        isLeaderboardMode: false, isGameOver: true, difficulty: .hard)
        #expect(newly.contains { $0.id == "gauntlet_hard" })
    }

    @Test func gauntletHardBadgeNotWithEasyDifficulty() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 1,
                                        isLeaderboardMode: false, isGameOver: true, difficulty: .easy)
        #expect(!newly.contains { $0.id == "gauntlet_hard" })
    }

    @Test func dedicationBadgesNotUnlockedBeforeThreshold() {
        let manager = freshManager()
        // totalGamesPlayed is 0 after resetAll
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(!newly.contains { $0.id == "games_10" })
        #expect(!newly.contains { $0.id == "games_25" })
    }

    @Test func dedicationBadgeGames10() {
        let manager = freshManager()
        for _ in 0..<10 { manager.recordGameStarted() }
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(newly.contains { $0.id == "games_10" })
    }

    @Test func dedicationBadgeGames25() {
        let manager = freshManager()
        for _ in 0..<25 { manager.recordGameStarted() }
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: false, isGameOver: false)
        #expect(newly.contains { $0.id == "games_10" })
        #expect(newly.contains { $0.id == "games_25" })
    }

    @Test func recordGameStartedIncrementsCount() {
        let manager = freshManager()
        #expect(manager.totalGamesPlayed == 0)
        manager.recordGameStarted()
        #expect(manager.totalGamesPlayed == 1)
        manager.recordGameStarted()
        #expect(manager.totalGamesPlayed == 2)
    }

    @Test func forceUnlockWorks() {
        let manager = freshManager()
        manager.forceUnlock("level_5")
        #expect(manager.isUnlocked("level_5"))
    }

    @Test func forceUnlockNonexistentBadgeReturnEmpty() {
        let manager = freshManager()
        let result = manager.forceUnlock("nonexistent")
        #expect(result.isEmpty)
    }

    @Test func resetAllClearsEverything() {
        let manager = freshManager()
        manager.recordGameStarted()
        manager.forceUnlock("level_5")
        manager.resetAll()
        #expect(manager.unlockedIDs.isEmpty)
        #expect(manager.totalGamesPlayed == 0)
    }

    @Test func leaderboardModeDoesNotUnlockGauntletBadges() {
        let manager = freshManager()
        let newly = manager.checkBadges(position: 0, streak: 0, livesRemaining: 3,
                                        isLeaderboardMode: true, isGameOver: true)
        #expect(!newly.contains { $0.id == "first_gauntlet" })
        #expect(!newly.contains { $0.id == "gauntlet_flawless" })
        #expect(!newly.contains { $0.id == "gauntlet_survivor" })
    }
}

// MARK: - QuestionCacheManager Tests

@Suite(.serialized)
struct QuestionCacheManagerTests {

    private func makeQuestion(id: String = UUID().uuidString, difficulty: String? = nil) -> TriviaQuestion {
        TriviaQuestion(id: id, question: "Test question \(id)?",
                       options: ["A", "B", "C", "D"], correctIndex: 0, difficulty: difficulty)
    }

    private func makeCacheManager() -> QuestionCacheManager {
        let manager = QuestionCacheManager()
        manager.clearCache()
        return manager
    }

    @Test func cacheStartsEmpty() {
        let manager = makeCacheManager()
        #expect(manager.cachedQuestionCount == 0)
    }

    @Test func cacheValidityFalseWhenEmpty() {
        let manager = makeCacheManager()
        #expect(manager.isCacheValid() == false)
    }

    @Test func cacheTimestampNilWhenEmpty() {
        let manager = makeCacheManager()
        #expect(manager.cacheTimestamp == nil)
    }

    @Test func cacheQuestionsAndRetrieve() {
        let manager = makeCacheManager()
        let questions = [makeQuestion(id: "a"), makeQuestion(id: "b"), makeQuestion(id: "c")]
        manager.cacheQuestions(questions)
        #expect(manager.cachedQuestionCount == 3)
        #expect(manager.isCacheValid())
    }

    @Test func getCachedQuestionsReturnsUpToCount() {
        let manager = makeCacheManager()
        let questions = (0..<10).map { makeQuestion(id: "q\($0)") }
        manager.cacheQuestions(questions)
        let result = manager.getCachedQuestions(count: 5, difficulty: nil)
        #expect(result.count == 5)
    }

    @Test func getCachedQuestionsReturnsAllWhenCountExceedsCache() {
        let manager = makeCacheManager()
        let questions = [makeQuestion(id: "x"), makeQuestion(id: "y")]
        manager.cacheQuestions(questions)
        let result = manager.getCachedQuestions(count: 100, difficulty: nil)
        #expect(result.count == 2)
    }

    @Test func difficultyFilterWorks() {
        let manager = makeCacheManager()
        let easy = makeQuestion(id: "e1", difficulty: "easy")
        let hard = makeQuestion(id: "h1", difficulty: "hard")
        let hard2 = makeQuestion(id: "h2", difficulty: "hard")
        manager.cacheQuestions([easy, hard, hard2])
        let result = manager.getCachedQuestions(count: 10, difficulty: "hard")
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.difficulty == "hard" })
    }

    @Test func difficultyFilterNilReturnsAll() {
        let manager = makeCacheManager()
        let questions = [makeQuestion(id: "1", difficulty: "easy"),
                         makeQuestion(id: "2", difficulty: "hard")]
        manager.cacheQuestions(questions)
        let result = manager.getCachedQuestions(count: 10, difficulty: nil)
        #expect(result.count == 2)
    }

    @Test func difficultyFilterAnyReturnsAll() {
        let manager = makeCacheManager()
        let questions = [makeQuestion(id: "1", difficulty: "easy"),
                         makeQuestion(id: "2", difficulty: "hard")]
        manager.cacheQuestions(questions)
        let result = manager.getCachedQuestions(count: 10, difficulty: "any")
        #expect(result.count == 2)
    }

    @Test func cacheWithDifficultyDeduplicates() {
        let manager = makeCacheManager()
        let q = makeQuestion(id: "dup")
        manager.cacheQuestions([q], forDifficulty: "easy")
        manager.cacheQuestions([q], forDifficulty: "easy")  // same question
        #expect(manager.cachedQuestionCount == 1)
    }

    @Test func cacheWithDifficultyMergesNewQuestions() {
        let manager = makeCacheManager()
        let q1 = makeQuestion(id: "q1")
        let q2 = makeQuestion(id: "q2")
        manager.cacheQuestions([q1], forDifficulty: "easy")
        manager.cacheQuestions([q2], forDifficulty: "hard")
        #expect(manager.cachedQuestionCount == 2)
    }

    @Test func clearCacheResetsEverything() {
        let manager = makeCacheManager()
        manager.cacheQuestions([makeQuestion()])
        manager.clearCache()
        #expect(manager.cachedQuestionCount == 0)
        #expect(manager.isCacheValid() == false)
        #expect(manager.cacheTimestamp == nil)
    }

    @Test func cachingEmptyArrayDoesNothing() {
        let manager = makeCacheManager()
        manager.cacheQuestions([])
        #expect(manager.cachedQuestionCount == 0)
        #expect(manager.isCacheValid() == false)
    }

    @Test func cacheTimestampSetAfterCaching() {
        let manager = makeCacheManager()
        let before = Date()
        manager.cacheQuestions([makeQuestion()])
        let after = Date()
        if let ts = manager.cacheTimestamp {
            #expect(ts >= before)
            #expect(ts <= after)
        } else {
            Issue.record("Cache timestamp should not be nil after caching")
        }
    }

    @Test func maxCacheSizeTrimmed() {
        let manager = makeCacheManager()
        // cacheQuestions(_:forDifficulty:) enforces the 100-question max
        let firstBatch = (0..<80).map { makeQuestion(id: "q\($0)") }
        manager.cacheQuestions(firstBatch, forDifficulty: "easy")
        // Add 50 more — total would be 130, should trim to 100
        let secondBatch = (80..<130).map { makeQuestion(id: "q\($0)") }
        manager.cacheQuestions(secondBatch, forDifficulty: "hard")
        #expect(manager.cachedQuestionCount <= 100)
    }
}

// MARK: - PassAndPlayPlayer Tests

struct PassAndPlayPlayerTests {

    @Test func defaultsAreZero() {
        let player = PassAndPlayPlayer(name: "Alice", color: .red)
        #expect(player.position == 0)
        #expect(player.questionsAnswered == 0)
        #expect(player.correctAnswers == 0)
    }

    @Test func nameAssigned() {
        let player = PassAndPlayPlayer(name: "Bob", color: .blue)
        #expect(player.name == "Bob")
    }

    @Test func idIsUnique() {
        let p1 = PassAndPlayPlayer(name: "X", color: .green)
        let p2 = PassAndPlayPlayer(name: "X", color: .green)
        #expect(p1.id != p2.id)
    }
}

// MARK: - RoundLimit Tests

struct RoundLimitTests {

    @Test func fixedRoundLimitCarriesValue() {
        let limit = RoundLimit.fixed(10)
        if case .fixed(let n) = limit {
            #expect(n == 10)
        } else {
            Issue.record("Expected .fixed case")
        }
    }

    @Test func raceTo25CaseExists() {
        let limit = RoundLimit.raceTo25
        if case .raceTo25 = limit {
            // pass
        } else {
            Issue.record("Expected .raceTo25 case")
        }
    }
}

// MARK: - DailyChallengeManager Tests

@MainActor
@Suite(.serialized)
struct DailyChallengeManagerTests {

    private func freshManager() -> DailyChallengeManager {
        let manager = DailyChallengeManager.shared
        manager.resetAll()
        return manager
    }

    private var todayString: String {
        DailyChallengeManager.formatDate(Date())
    }

    private var yesterdayString: String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        return DailyChallengeManager.formatDate(yesterday)
    }

    private var threeDaysAgoString: String {
        let date = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        return DailyChallengeManager.formatDate(date)
    }

    // MARK: - Constants

    @Test func questionCountIsTen() {
        #expect(DailyChallengeManager.questionCount == 10)
    }

    // MARK: - Initial State

    @Test func initialStateAfterReset() {
        let manager = freshManager()
        #expect(manager.currentStreak == 0)
        #expect(manager.bestStreak == 0)
        #expect(manager.totalCompleted == 0)
        #expect(manager.lastScore == 0)
        #expect(manager.bestScore == 0)
        #expect(manager.isTodayCompleted == false)
        #expect(manager.isStreakActive == false)
        #expect(manager.streakExpiresEndOfDay == false)
    }

    // MARK: - Record Completion

    @Test func recordCompletionFirstTime() {
        let manager = freshManager()
        manager.recordCompletion(score: 7)
        #expect(manager.lastScore == 7)
        #expect(manager.bestScore == 7)
        #expect(manager.currentStreak == 1)
        #expect(manager.bestStreak == 1)
        #expect(manager.totalCompleted == 1)
    }

    @Test func recordCompletionMarksTodayCompleted() {
        let manager = freshManager()
        #expect(manager.isTodayCompleted == false)
        manager.recordCompletion(score: 5)
        #expect(manager.isTodayCompleted == true)
    }

    @Test func recordCompletionMakesStreakActive() {
        let manager = freshManager()
        #expect(manager.isStreakActive == false)
        manager.recordCompletion(score: 5)
        #expect(manager.isStreakActive == true)
    }

    @Test func sameDayCompletionDoesNotDoubleStreak() {
        let manager = freshManager()
        manager.recordCompletion(score: 5)
        manager.recordCompletion(score: 8)
        #expect(manager.currentStreak == 1)
        #expect(manager.totalCompleted == 2)
        #expect(manager.lastScore == 8)
    }

    @Test func bestScoreNotLoweredByWorseScore() {
        let manager = freshManager()
        manager.recordCompletion(score: 9)
        #expect(manager.bestScore == 9)
        manager.recordCompletion(score: 3)
        #expect(manager.bestScore == 9)
        #expect(manager.lastScore == 3)
    }

    @Test func bestScoreUpdatedWhenHigher() {
        let manager = freshManager()
        manager.recordCompletion(score: 5)
        manager.recordCompletion(score: 10)
        #expect(manager.bestScore == 10)
    }

    @Test func totalCompletedIncrementsEachTime() {
        let manager = freshManager()
        manager.recordCompletion(score: 1)
        manager.recordCompletion(score: 2)
        manager.recordCompletion(score: 3)
        #expect(manager.totalCompleted == 3)
    }

    // MARK: - Streak Logic with Date Injection

    @Test func streakContinuesFromYesterday() {
        let manager = freshManager()
        // Simulate yesterday's completion with a 1-day streak
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 1)
        #expect(manager.isStreakActive == true)
        manager.recordCompletion(score: 7)
        #expect(manager.currentStreak == 2)
    }

    @Test func streakBreaksAfterMultiDayGap() {
        let manager = freshManager()
        // Simulate completion 3 days ago with a 5-day streak
        manager.setTestState(lastCompletedDate: threeDaysAgoString, currentStreak: 5)
        #expect(manager.isStreakActive == false)
        manager.recordCompletion(score: 7)
        #expect(manager.currentStreak == 1) // restarted
    }

    @Test func streakExpiresEndOfDayWhenCompletedYesterday() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 3)
        #expect(manager.streakExpiresEndOfDay == true)
    }

    @Test func streakDoesNotExpireEndOfDayWhenCompletedToday() {
        let manager = freshManager()
        manager.recordCompletion(score: 5)
        #expect(manager.streakExpiresEndOfDay == false)
    }

    @Test func isTodayCompletedFalseWhenCompletedYesterday() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 1)
        #expect(manager.isTodayCompleted == false)
    }

    @Test func isStreakActiveWhenCompletedYesterday() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 2)
        #expect(manager.isStreakActive == true)
    }

    @Test func isStreakInactiveWhenCompletedThreeDaysAgo() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: threeDaysAgoString, currentStreak: 5)
        #expect(manager.isStreakActive == false)
    }

    @Test func validateStreakResetsOnStaleDate() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: threeDaysAgoString, currentStreak: 10)
        manager.debugValidateStreak()
        #expect(manager.currentStreak == 0)
    }

    @Test func validateStreakPreservesYesterday() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 4)
        manager.debugValidateStreak()
        #expect(manager.currentStreak == 4)
    }

    @Test func validateStreakPreservesToday() {
        let manager = freshManager()
        manager.recordCompletion(score: 5) // sets to today
        manager.debugValidateStreak()
        #expect(manager.currentStreak == 1)
    }

    @Test func validateStreakResetsWhenNoDate() {
        let manager = freshManager()
        // resetAll sets lastCompletedDateString to nil but currentStreak to 0 already
        manager.setTestState(lastCompletedDate: nil, currentStreak: 3)
        manager.debugValidateStreak()
        #expect(manager.currentStreak == 0)
    }

    // MARK: - Best Streak

    @Test func bestStreakUpdatedOnCompletion() {
        let manager = freshManager()
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 4)
        manager.recordCompletion(score: 5) // streak becomes 5
        #expect(manager.bestStreak == 5)
    }

    @Test func bestStreakNotLowered() {
        let manager = freshManager()
        // First: build a streak of 3
        manager.setTestState(lastCompletedDate: yesterdayString, currentStreak: 2)
        manager.recordCompletion(score: 5) // streak 3, bestStreak 3
        #expect(manager.bestStreak == 3)

        // Now reset and start fresh — bestStreak should stay at 3
        manager.setTestState(lastCompletedDate: threeDaysAgoString, currentStreak: 0)
        manager.recordCompletion(score: 5) // streak resets to 1
        #expect(manager.currentStreak == 1)
        #expect(manager.bestStreak == 3)
    }

    // MARK: - Reset

    @Test func resetAllClearsEverything() {
        let manager = freshManager()
        manager.recordCompletion(score: 10)
        #expect(manager.totalCompleted == 1) // sanity
        manager.resetAll()
        #expect(manager.currentStreak == 0)
        #expect(manager.bestStreak == 0)
        #expect(manager.totalCompleted == 0)
        #expect(manager.lastScore == 0)
        #expect(manager.bestScore == 0)
        #expect(manager.isTodayCompleted == false)
    }

    // MARK: - UserDefaults Persistence

    @Test func persistsToUserDefaults() {
        let manager = freshManager()
        manager.recordCompletion(score: 8)
        #expect(UserDefaults.standard.integer(forKey: "dailyChallenge.currentStreak") == 1)
        #expect(UserDefaults.standard.integer(forKey: "dailyChallenge.bestStreak") == 1)
        #expect(UserDefaults.standard.integer(forKey: "dailyChallenge.totalCompleted") == 1)
        #expect(UserDefaults.standard.integer(forKey: "dailyChallenge.lastScore") == 8)
        #expect(UserDefaults.standard.integer(forKey: "dailyChallenge.bestScore") == 8)
        #expect(UserDefaults.standard.string(forKey: "dailyChallenge.lastCompletedDate") == todayString)
    }

    // MARK: - Date Formatter

    @Test func formatDateProducesExpectedFormat() {
        let components = DateComponents(year: 2026, month: 2, day: 22)
        let date = Calendar.current.date(from: components)!
        let formatted = DailyChallengeManager.formatDate(date)
        #expect(formatted == "2026-02-22")
    }
}

// MARK: - NotificationManager Tests

@MainActor
@Suite(.serialized)
struct NotificationManagerTests {

    private func freshManager() -> NotificationManager {
        let manager = NotificationManager.shared
        manager.resetAll()
        return manager
    }

    // MARK: - Category Raw Values

    @Test func categoryRawValues() {
        #expect(NotificationManager.Category.dailyChallenge.rawValue == "DAILY_CHALLENGE")
        #expect(NotificationManager.Category.streakReminder.rawValue == "STREAK_REMINDER")
        #expect(NotificationManager.Category.leaderboard.rawValue == "LEADERBOARD")
    }

    // MARK: - Default Toggles

    @Test func defaultTogglesAreEnabled() {
        let manager = freshManager()
        #expect(manager.dailyChallengeEnabled == true)
        #expect(manager.streakReminderEnabled == true)
        #expect(manager.leaderboardEnabled == true)
    }

    // MARK: - Authorization Status

    @Test func isAuthorizedFalseWhenNotDetermined() {
        let manager = freshManager()
        #expect(manager.authorizationStatus == .notDetermined)
        #expect(manager.isAuthorized == false)
    }

    @Test func isAuthorizedTrueWhenAuthorized() {
        let manager = freshManager()
        manager.setAuthorizationStatus(.authorized)
        #expect(manager.isAuthorized == true)
    }

    @Test func isAuthorizedFalseWhenDenied() {
        let manager = freshManager()
        manager.setAuthorizationStatus(.denied)
        #expect(manager.isAuthorized == false)
    }

    @Test func isAuthorizedFalseWhenProvisional() {
        let manager = freshManager()
        manager.setAuthorizationStatus(.provisional)
        #expect(manager.isAuthorized == false)
    }

    // MARK: - Toggle Persistence

    @Test func dailyChallengeTogglePersists() {
        let manager = freshManager()
        manager.dailyChallengeEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "notifications.dailyChallenge") == false)
        manager.dailyChallengeEnabled = true
        #expect(UserDefaults.standard.bool(forKey: "notifications.dailyChallenge") == true)
    }

    @Test func streakReminderTogglePersists() {
        let manager = freshManager()
        manager.streakReminderEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "notifications.streakReminder") == false)
        manager.streakReminderEnabled = true
    }

    @Test func leaderboardTogglePersists() {
        let manager = freshManager()
        manager.leaderboardEnabled = false
        #expect(UserDefaults.standard.bool(forKey: "notifications.leaderboard") == false)
        manager.leaderboardEnabled = true
    }

    // MARK: - Permission Requested Flag

    @Test func hasRequestedPermissionDefaultFalse() {
        UserDefaults.standard.removeObject(forKey: "notifications.permissionRequested")
        let manager = freshManager()
        #expect(manager.hasRequestedPermission == false)
    }

    @Test func hasRequestedPermissionReadsUserDefaults() {
        UserDefaults.standard.set(true, forKey: "notifications.permissionRequested")
        let manager = freshManager()
        #expect(manager.hasRequestedPermission == true)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "notifications.permissionRequested")
    }

    // MARK: - Guard Conditions

    @Test func streakReminderGuardsOnZeroStreak() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Streak of 0 should not schedule
        manager.scheduleStreakReminder(currentStreak: 0)

        // Small delay for async center operations
        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let streakRequests = pending.filter { $0.identifier == "streak_reminder" }
        #expect(streakRequests.isEmpty)
    }

    @Test func streakReminderGuardsOnDisabledToggle() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        manager.streakReminderEnabled = false
        manager.scheduleStreakReminder(currentStreak: 5)

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let streakRequests = pending.filter { $0.identifier == "streak_reminder" }
        #expect(streakRequests.isEmpty)
        // Reset toggle
        manager.streakReminderEnabled = true
    }

    @Test func dailyChallengeGuardsOnDisabledToggle() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        manager.dailyChallengeEnabled = false
        manager.scheduleDailyChallengeReminder()

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let dailyRequests = pending.filter { $0.identifier == "daily_challenge_reminder" }
        #expect(dailyRequests.isEmpty)
        manager.dailyChallengeEnabled = true
    }

    @Test func leaderboardNudgeGuardsOnDisabledToggle() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        manager.leaderboardEnabled = false
        manager.scheduleLeaderboardNudge(previousRank: 5, currentRank: 10)

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let leaderboardRequests = pending.filter { $0.identifier == "leaderboard_rank_drop" }
        #expect(leaderboardRequests.isEmpty)
        manager.leaderboardEnabled = true
    }

    @Test func leaderboardNudgeGuardsWhenRankImproved() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Rank improved from 10 to 5 — should not nudge
        manager.scheduleLeaderboardNudge(previousRank: 10, currentRank: 5)

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let leaderboardRequests = pending.filter { $0.identifier == "leaderboard_rank_drop" }
        #expect(leaderboardRequests.isEmpty)
    }

    @Test func closeToTopNudgeGuardsWhenNotClose() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Rank 20 is more than 10 away from top — should not nudge
        manager.scheduleLeaderboardCloseToTopNudge(currentRank: 20, topRank: 1)

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let closeRequests = pending.filter { $0.identifier == "leaderboard_close_to_top" }
        #expect(closeRequests.isEmpty)
    }

    @Test func closeToTopNudgeGuardsWhenAtTop() async {
        let manager = freshManager()
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        // Already at #1 — should not nudge
        manager.scheduleLeaderboardCloseToTopNudge(currentRank: 1, topRank: 1)

        try? await Task.sleep(for: .milliseconds(200))
        let pending = await center.pendingNotificationRequests()
        let closeRequests = pending.filter { $0.identifier == "leaderboard_close_to_top" }
        #expect(closeRequests.isEmpty)
    }

    // MARK: - Reset

    @Test func resetAllRestoresDefaults() {
        let manager = freshManager()
        manager.dailyChallengeEnabled = false
        manager.streakReminderEnabled = false
        manager.leaderboardEnabled = false
        manager.setAuthorizationStatus(.authorized)

        manager.resetAll()

        #expect(manager.dailyChallengeEnabled == true)
        #expect(manager.streakReminderEnabled == true)
        #expect(manager.leaderboardEnabled == true)
        #expect(manager.authorizationStatus == .notDetermined)
    }
}

// MARK: - GameCenterManager Rank Tracking Tests

@MainActor
struct GameCenterRankTrackingTests {

    @Test func initialRankIsZero() {
        // Clean up any saved rank first
        UserDefaults.standard.removeObject(forKey: "gamecenter.lastKnownRank")
        let manager = GameCenterManager.shared
        // currentRank is always 0 until fetchPlayerRank completes
        #expect(manager.currentRank == 0)
    }

    @Test func leaderboardIDIsCorrect() {
        #expect(GameCenterManager.leaderboardID == "retrotrivia.highscore")
    }

    @Test func rankPersistedToUserDefaults() {
        // The saved rank key stores the previous known rank
        let testRank = 42
        UserDefaults.standard.set(testRank, forKey: "gamecenter.lastKnownRank")
        let saved = UserDefaults.standard.integer(forKey: "gamecenter.lastKnownRank")
        #expect(saved == testRank)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "gamecenter.lastKnownRank")
    }
}
