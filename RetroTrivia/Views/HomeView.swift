//
//  HomeView.swift
//  RetroTrivia
//

import SwiftUI

struct HomeView: View {
    @Environment(GameState.self) var gameState
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    @Environment(GameCenterManager.self) var gameCenterManager
    let onPlayTapped: () -> Void

    enum SheetType: Identifiable {
        case settings
        case leaderboard

        var id: Int {
            switch self {
            case .settings: return 0
            case .leaderboard: return 1
            }
        }
    }

    @State private var activeSheet: SheetType?

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                // Header buttons
                HStack(spacing: 12) {
                    Spacer()

                    // Music toggle button
                    Button(action: {
                        audioManager.playSoundEffect(named: "music-toggle")
                        audioManager.isMusicEnabled.toggle()
                    }) {
                        Image(systemName: audioManager.isMusicEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(audioManager.isMusicEnabled ? Color("NeonPink") : Color.white.opacity(0.4))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: audioManager.isMusicEnabled)

                    // Leaderboard button (only when authenticated)
                    if gameCenterManager.isAuthenticated {
                        Button(action: {
                            audioManager.playSoundEffect(named: "button-tap")
                            // Auto-enable leaderboard mode when viewing leaderboard
                            if !gameState.gameSettings.leaderboardMode {
                                gameState.gameSettings.leaderboardMode = true
                                gameState.gameSettings.save()
                            }
                            activeSheet = .leaderboard
                        }) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color("NeonYellow"))
                                .frame(width: 42, height: 42)
                                .background(gameState.gameSettings.leaderboardMode
                                    ? Color("NeonYellow").opacity(0.2)
                                    : Color.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .sensoryFeedback(.impact(weight: .medium), trigger: activeSheet == .leaderboard)
                    }

                    // Settings button
                    Button(action: {
                        activeSheet = .settings
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color("NeonPink"))
                            .frame(width: 42, height: 42)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: activeSheet == .settings)
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
        .fullScreenCover(item: $activeSheet) { sheetType in
            switch sheetType {
            case .settings:
                SettingsView()
            case .leaderboard:
                GameCenterLeaderboardView()
            }
        }
        .onAppear {
            activeSheet = nil
        }
    }
}

#Preview {
    HomeView(onPlayTapped: {})
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
        .environment(GameCenterManager.shared)
}
