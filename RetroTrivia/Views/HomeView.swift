//
//  HomeView.swift
//  RetroTrivia
//

import SwiftUI
import Combine

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
    @State private var currentPhraseIndex = 0
    @State private var showDifficultyPicker = false
    @State private var pendingLeaderboardMode = true

    private let retroPhrases = [
        "Totally Tubular!",
        "Like, Totally Awesome!",
        "Gag Me With a Spoon!",
        "Radical!",
        "Gnarly!",
        "To the Max!",
        "Grody to the Max!",
        "Fer Sure!",
        "Bodacious!",
        "Righteous!"
    ]

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
                            activeSheet = .leaderboard
                        }) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color("NeonYellow"))
                                .frame(width: 42, height: 42)
                                .background(Color.white.opacity(0.08))
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

                // App icon with retro glow
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color("NeonPink").opacity(0.6), radius: 20)
                    .shadow(color: Color("ElectricBlue").opacity(0.4), radius: 30)
                    .padding(.bottom, 8)

                VStack(spacing: 12) {
                    Text("RETROTRIVIA")
                        .retroTitle()

                    Text("80s Music Challenge")
                        .retroSubtitle()
                }

                // Scrolling 80s phrases
                Text(retroPhrases[currentPhraseIndex])
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("ElectricBlue")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink").opacity(0.5), radius: 8)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.5), value: currentPhraseIndex)
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

                HStack(spacing: 16) {
                    // Play button (leaderboard mode)
                    VStack(spacing: 4) {
                        RetroButton("Play", variant: .primary) {
                            audioManager.playSoundEffect(named: "button-tap")
                            pendingLeaderboardMode = true
                            showDifficultyPicker = true
                        }
                        Text("2-minute challenge")
                            .font(.caption)
                            .foregroundStyle(Color("NeonPink").opacity(0.7))
                    }

                    // Practice button (casual mode)
                    VStack(spacing: 4) {
                        RetroButton("Practice", variant: .secondary) {
                            audioManager.playSoundEffect(named: "button-tap")
                            pendingLeaderboardMode = false
                            showDifficultyPicker = true
                        }
                        Text("No time limit")
                            .font(.caption)
                            .foregroundStyle(Color("ElectricBlue").opacity(0.7))
                    }
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
        .onReceive(Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()) { _ in
            withAnimation {
                currentPhraseIndex = (currentPhraseIndex + 1) % retroPhrases.count
            }
        }
        .fullScreenCover(isPresented: $showDifficultyPicker) {
            DifficultyPickerOverlay(
                onSelect: { difficulty in
                    questionManager.filterConfig.difficulty = difficulty
                    questionManager.filterConfig.save()
                    showDifficultyPicker = false
                    startGame(leaderboardMode: pendingLeaderboardMode)
                },
                onCancel: {
                    showDifficultyPicker = false
                }
            )
        }
    }

    private func startGame(leaderboardMode: Bool) {
        audioManager.playSoundEffect(named: "button-tap")
        gameState.gameSettings.leaderboardMode = leaderboardMode

        // Timer is always enabled (10 seconds per question)
        gameState.gameSettings.timerEnabled = true

        // Leaderboard mode uses 5 lives + 2 minute game timer
        if leaderboardMode {
            gameState.gameSettings.livesEnabled = true
            gameState.gameSettings.startingLives = GameSettings.leaderboardLives
        }

        gameState.gameSettings.save()
        gameState.resetGame()
        questionManager.resetSession()
        audioManager.playGameplayMusic()
        onPlayTapped()
    }
}

// MARK: - Difficulty Picker Overlay

private struct DifficultyPickerOverlay: View {
    @Environment(AudioManager.self) var audioManager
    let onSelect: (Difficulty) -> Void
    let onCancel: () -> Void

    private let difficulties: [(Difficulty, String)] = [
        (.any, "Mix of all difficulties"),
        (.easy, "Beginner friendly"),
        (.medium, "Moderate challenge"),
        (.hard, "Expert level"),
    ]

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 24) {
                Spacer()

                Text("Select Difficulty")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("HotMagenta")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink").opacity(0.8), radius: 10)

                Spacer()
                    .frame(height: 8)

                ForEach(difficulties, id: \.0) { difficulty, subtitle in
                    Button {
                        audioManager.playSoundEffect(named: "button-tap")
                        onSelect(difficulty)
                    } label: {
                        VStack(spacing: 4) {
                            Text(difficulty.displayName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .fontDesign(.rounded)
                                .foregroundStyle(.white)

                            Text(subtitle)
                                .font(.caption)
                                .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .frame(minWidth: 260)
                        .background(Color("RetroPurple"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color("NeonPink"), Color("ElectricBlue")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: Color("NeonPink").opacity(0.4), radius: 8)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Spacer()

                Button {
                    audioManager.playSoundEffect(named: "button-tap")
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.body)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color("NeonPink").opacity(0.8))
                }
                .padding(.bottom, 40)
            }
            .padding()
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
