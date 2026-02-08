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

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            if let error = error {
                print("GameCenter auth error: \(error.localizedDescription)")
            }
            Task { @MainActor in
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
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
        } catch {
            print("Failed to submit score: \(error.localizedDescription)")
        }
    }
}
