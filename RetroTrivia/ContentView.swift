//
//  ContentView.swift
//  RetroTrivia
//
//  Created by Craig Oaks on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 24) {
                Text("RETROTRIVIA")
                    .retroTitle()

                Text("80s Music Challenge")
                    .retroSubtitle()

                Spacer()

                VStack(spacing: 16) {
                    Text("Position: \(gameState.currentPosition)")
                        .retroBody()
                    Text("High Score: \(gameState.highScorePosition)")
                        .retroHeading()
                }

                Spacer()

                RetroButton("Play Now", variant: .primary) {
                    gameState.incrementPosition()
                }

                RetroButton("Reset", variant: .secondary) {
                    gameState.resetGame()
                }

                Text("Stage 2 Complete")
                    .retroBody()
                    .padding(.top, 20)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}
