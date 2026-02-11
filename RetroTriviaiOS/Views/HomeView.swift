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
    @Environment(BadgeManager.self) var badgeManager
    let onPlayTapped: () -> Void
    let onPassAndPlayTapped: (PassAndPlaySession) -> Void

    enum SheetType: Identifiable {
        case settings
        case badges
        case passAndPlaySetup

        var id: Int {
            switch self {
            case .settings: return 0
            case .badges: return 2
            case .passAndPlaySetup: return 3
            }
        }
    }

    @State private var activeSheet: SheetType?
    @State private var currentPhraseIndex = 0
    @State private var showDifficultyPicker = false

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
        GeometryReader { geo in
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
                                GameCenterLeaderboard.show()
                            }) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color("NeonYellow"))
                                    .frame(width: 42, height: 42)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                        }

                        // Badge gallery button
                        Button(action: {
                            audioManager.playSoundEffect(named: "button-tap")
                            activeSheet = .badges
                        }) {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "medal.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color("NeonYellow"))
                                    .frame(width: 42, height: 42)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                                // Badge count pip
                                if badgeManager.unlockedIDs.count > 0 {
                                    Text("\(badgeManager.unlockedIDs.count)")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundStyle(.black)
                                        .padding(3)
                                        .background(Color("NeonYellow"))
                                        .clipShape(Circle())
                                        .offset(x: 4, y: -4)
                                }
                            }
                        }
                        .sensoryFeedback(.impact(weight: .light), trigger: activeSheet == .badges)

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

                    VStack(spacing: 12) {
                        // Play — ranked leaderboard mode
                        GameModeCard(
                            "Play",
                            details: [("clock", "2 min"), ("trophy", "Ranked")],
                            accent: Color("NeonPink"),
                            isHero: true
                        ) {
                            audioManager.playSoundEffect(named: "button-tap")
                            questionManager.filterConfig.difficulty = .any
                            questionManager.filterConfig.save()
                            startGame(leaderboardMode: true)
                        }

                        // Gauntlet — survival mode
                        GameModeCard(
                            "Gauntlet",
                            details: [("heart.fill", "3 lives"), ("infinity", "No clock")],
                            accent: Color("ElectricBlue")
                        ) {
                            audioManager.playSoundEffect(named: "button-tap")
                            showDifficultyPicker = true
                        }

                        // Pass & Play — local multiplayer
                        GameModeCard(
                            "Pass & Play",
                            details: [("person.2.fill", "2-4 players"), ("wifi.slash", "Local only")],
                            accent: Color("NeonYellow")
                        ) {
                            audioManager.playSoundEffect(named: "button-tap")
                            activeSheet = .passAndPlaySetup
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
                .padding(.top, max(geo.safeAreaInsets.top, 50) + 8)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 20))
                .padding(.horizontal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .ignoresSafeArea()
        .fullScreenCover(item: $activeSheet) { sheetType in
            switch sheetType {
            case .settings:
                SettingsView()
            case .badges:
                BadgeGalleryView {
                    activeSheet = nil
                }
                .environment(badgeManager)
            case .passAndPlaySetup:
                PassAndPlaySetupView(
                    onStart: { session in
                        audioManager.playSoundEffect(named: "button-tap")
                        activeSheet = nil
                        onPassAndPlayTapped(session)
                    },
                    onCancel: {
                        activeSheet = nil
                    }
                )
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
                    startGame(leaderboardMode: false)
                },
                onCancel: {
                    showDifficultyPicker = false
                }
            )
        }
    }

    private func startGame(leaderboardMode: Bool) {
        audioManager.playSoundEffect(named: "button-tap")
        #if DEBUG
        // Bundled question mode is never leaderboard-eligible
        gameState.gameSettings.leaderboardMode = leaderboardMode && !questionManager.forceBundleMode
        #else
        gameState.gameSettings.leaderboardMode = leaderboardMode
        #endif

        // Per-question timer always enabled (10 seconds per question)
        gameState.gameSettings.timerEnabled = true

        if leaderboardMode {
            // Play: 2-minute game timer, no lives
            gameState.gameSettings.livesEnabled = false
        } else {
            // Gauntlet: no game timer, 3 lives
            gameState.gameSettings.livesEnabled = true
            gameState.gameSettings.startingLives = GameSettings.gauntletLives
        }

        gameState.gameSettings.save()
        gameState.resetGame()
        questionManager.resetSession()
        audioManager.playGameplayMusic()
        onPlayTapped()
    }
}

// MARK: - Game Mode Card

private struct GameModeCard: View {
    let title: String
    let details: [(icon: String, text: String)]
    let accent: Color
    var isHero: Bool = false
    let action: () -> Void

    init(_ title: String, details: [(icon: String, text: String)], accent: Color, isHero: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.details = details
        self.accent = accent
        self.isHero = isHero
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                // Neon accent strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 4)
                    .shadow(color: accent.opacity(0.9), radius: 6)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.black)
                        .fontDesign(.rounded)
                        .foregroundStyle(.white)

                    HStack(spacing: 14) {
                        ForEach(0..<details.count, id: \.self) { i in
                            Label(details[i].text, systemImage: details[i].icon)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.opacity(isHero ? 1.0 : 0.8))
                        }
                    }
                }
                .padding(.leading, 16)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(isHero ? accent.opacity(0.1) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(accent.opacity(isHero ? 0.5 : 0.25), lineWidth: isHero ? 1.5 : 1)
            )
            .shadow(color: accent.opacity(isHero ? 0.3 : 0.12), radius: isHero ? 10 : 5)
        }
        .buttonStyle(ScaleButtonStyle())
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
    HomeView(onPlayTapped: {}, onPassAndPlayTapped: { _ in })
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
        .environment(GameCenterManager.shared)
}
