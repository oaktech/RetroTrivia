//
//  HomeView.swift
//  RetroTrivia
//

import SwiftUI

struct HomeView: View {
    @Environment(GameState.self) var gameState
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    let onPlayTapped: () -> Void

    @State private var showSettings = false

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                // Header buttons
                HStack {
                    Spacer()

                    // Settings button
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(Color("NeonPink"))
                            .padding()
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: showSettings)

                    // Music toggle button
                    Button(action: {
                        audioManager.playSoundEffect(named: "music-toggle")
                        audioManager.isMusicEnabled.toggle()
                    }) {
                        Image(systemName: audioManager.isMusicEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.title2)
                            .foregroundStyle(audioManager.isMusicEnabled ? Color("NeonPink") : Color.white.opacity(0.5))
                            .padding()
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: audioManager.isMusicEnabled)
                }

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
                    audioManager.playSoundEffect(named: "button-tap")
                    gameState.resetGame()
                    questionManager.resetSession()
                    audioManager.playGameplayMusic()
                    onPlayTapped()
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    HomeView(onPlayTapped: {})
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
}
