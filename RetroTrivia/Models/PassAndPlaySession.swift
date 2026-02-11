//
//  PassAndPlaySession.swift
//  RetroTrivia
//

import SwiftUI
import Foundation

struct PassAndPlayPlayer: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var position: Int = 0
    var questionsAnswered: Int = 0
    var correctAnswers: Int = 0
}

enum RoundLimit {
    case fixed(Int)   // 5, 10, or 15 questions per player
    case raceTo25     // first to node 25 wins
}

@Observable
class PassAndPlaySession {
    var players: [PassAndPlayPlayer]
    var currentPlayerIndex: Int = 0
    var roundLimit: RoundLimit
    var difficulty: Difficulty
    var isGameOver: Bool = false
    var askedQuestionIDs: Set<String> = []

    var currentPlayer: PassAndPlayPlayer { players[currentPlayerIndex] }
    var maxPosition: Int { players.map(\.position).max() ?? 0 }
    var winner: PassAndPlayPlayer? { players.max(by: { $0.position < $1.position }) }

    init(playerNames: [String], roundLimit: RoundLimit, difficulty: Difficulty) {
        let colors: [Color] = [Color("NeonPink"), Color("ElectricBlue"), Color("NeonYellow"), Color("HotMagenta")]
        self.players = playerNames.enumerated().map { index, name in
            PassAndPlayPlayer(name: name, color: colors[index % colors.count])
        }
        self.roundLimit = roundLimit
        self.difficulty = difficulty
    }

    func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
    }

    var isRoundComplete: Bool {
        guard case .fixed(let limit) = roundLimit else { return false }
        return players.allSatisfy { $0.questionsAnswered >= limit }
    }

    func checkWinCondition() -> Bool {
        // Check if any player hit 25 in race-to-25 mode
        if case .raceTo25 = roundLimit {
            return players.contains { $0.position >= 25 }
        }

        // Check if all players completed their fixed rounds
        return isRoundComplete
    }
}
