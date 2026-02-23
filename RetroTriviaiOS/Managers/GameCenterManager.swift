//
//  GameCenterManager.swift
//  RetroTrivia
//

import GameKit
import SwiftUI

@MainActor
@Observable
class GameCenterManager {
    static let shared = GameCenterManager()
    static let leaderboardID = "retrotrivia.highscore"

    var isAuthenticated = false

    /// The player's current leaderboard rank (0 if unknown).
    private(set) var currentRank: Int = 0

    /// The previously known rank, used to detect rank drops.
    private(set) var previousRank: Int = 0

    private static let savedRankKey = "gamecenter.lastKnownRank"

    private init() {
        self.previousRank = UserDefaults.standard.integer(forKey: Self.savedRankKey)
    }

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("GameCenter auth error: \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if GKLocalPlayer.local.isAuthenticated {
                    await self?.fetchPlayerRank()
                }
            }
        }
    }

    func submitScore(_ score: Int) async {
        guard isAuthenticated else { return }
        do {
            try await GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Self.leaderboardID]
            )
            // Refresh rank after submitting
            await fetchPlayerRank()
        } catch {
            print("Failed to submit score: \(error.localizedDescription)")
        }
    }

    // MARK: - Rank Tracking

    /// Fetch the player's current leaderboard rank and trigger notifications if it dropped.
    func fetchPlayerRank() async {
        guard isAuthenticated else { return }

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [Self.leaderboardID])
            guard let leaderboard = leaderboards.first else { return }

            let (entry, _) = try await leaderboard.loadEntries(
                for: [GKLocalPlayer.local],
                timeScope: .allTime
            )

            guard let localEntry = entry else { return }

            let newRank = localEntry.rank
            let oldRank = previousRank

            // Update stored rank
            previousRank = currentRank > 0 ? currentRank : oldRank
            currentRank = newRank
            UserDefaults.standard.set(newRank, forKey: Self.savedRankKey)

            // Check for rank drop and schedule notification
            if previousRank > 0 && newRank > previousRank {
                NotificationManager.shared.scheduleLeaderboardNudge(
                    previousRank: previousRank,
                    currentRank: newRank
                )
            }

            // Check if close to top
            if newRank > 1 && newRank <= 11 {
                NotificationManager.shared.scheduleLeaderboardCloseToTopNudge(
                    currentRank: newRank,
                    topRank: 1
                )
            }

        } catch {
            print("Failed to fetch player rank: \(error.localizedDescription)")
        }
    }
}
