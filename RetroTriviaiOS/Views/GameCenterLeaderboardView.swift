//
//  GameCenterLeaderboardView.swift
//  RetroTrivia
//

import GameKit
import SwiftUI
import UIKit

// TODO: GKGameCenterViewController deprecated in iOS 26 — update when SwiftUI replacement is available
struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let vc = GKGameCenterViewController(
            leaderboardID: GameCenterManager.leaderboardID,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            dismiss()
        }
    }
}
