//
//  GameMapView.swift
//  RetroTrivia
//

import SwiftUI

struct GameMapView: View {
    @Environment(GameState.self) var gameState
    let onBackTapped: () -> Void

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                HStack {
                    Button(action: onBackTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .retroBody()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                VStack(spacing: 20) {
                    Text("Game Map")
                        .retroTitle()

                    Text("Position: \(gameState.currentPosition)")
                        .retroHeading()

                    Text("Map coming in Stage 7")
                        .retroBody()
                        .opacity(0.7)
                }

                Spacer()
            }
        }
    }
}

#Preview {
    GameMapView(onBackTapped: {})
        .environment(GameState())
}
