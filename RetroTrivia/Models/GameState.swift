//
//  GameState.swift
//  RetroTrivia
//

import Foundation
import Observation

@MainActor
@Observable
class GameState {
    private static let currentPositionKey = "currentPosition"
    private static let highScorePositionKey = "highScorePosition"

    var currentPosition: Int {
        didSet {
            UserDefaults.standard.set(currentPosition, forKey: Self.currentPositionKey)
            if currentPosition > highScorePosition {
                highScorePosition = currentPosition
            }
        }
    }

    var highScorePosition: Int {
        didSet {
            UserDefaults.standard.set(highScorePosition, forKey: Self.highScorePositionKey)
        }
    }

    var gameSettings: GameSettings = GameSettings.load() {
        didSet {
            gameSettings.save()
        }
    }

    init() {
        self.currentPosition = UserDefaults.standard.integer(forKey: Self.currentPositionKey)
        self.highScorePosition = UserDefaults.standard.integer(forKey: Self.highScorePositionKey)
    }

    func incrementPosition() {
        currentPosition += 1
    }

    func decrementPosition() {
        if currentPosition > 0 {
            currentPosition -= 1
        }
    }

    func resetGame() {
        currentPosition = 0
    }
}
