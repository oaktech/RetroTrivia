//
//  GameCenterLeaderboardView.swift
//  RetroTrivia
//

import GameKit

enum GameCenterLeaderboard {
    static func show() {
        GKAccessPoint.shared.trigger(
            leaderboardID: GameCenterManager.leaderboardID,
            playerScope: .global,
            timeScope: .allTime,
            handler: nil
        )
    }
}
