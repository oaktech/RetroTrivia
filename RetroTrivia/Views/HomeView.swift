//
//  HomeView.swift
//  RetroTrivia
//

import SwiftUI

struct HomeView: View {
    @Environment(GameState.self) var gameState
    let onPlayTapped: () -> Void

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Text("RETROTRIVIA")
                        .retroTitle()

                    Text("80s Music Challenge")
                        .retroSubtitle()
                }

                VStack(spacing: 8) {
                    Text("Test your knowledge of")
                        .retroBody()
                    Text("the greatest decade in music!")
                        .retroBody()
                }
                .padding(.top, 8)

                Spacer()

                if gameState.highScorePosition > 0 {
                    VStack(spacing: 8) {
                        Text("High Score")
                            .retroBody()
                            .opacity(0.8)
                        Text("\(gameState.highScorePosition)")
                            .retroHeading()
                    }
                    .padding(.bottom, 20)
                }

                RetroButton("Play", variant: .primary) {
                    onPlayTapped()
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView(onPlayTapped: {})
        .environment(GameState())
}
