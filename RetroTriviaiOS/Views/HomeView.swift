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
    @Environment(\.horizontalSizeClass) private var sizeClass
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

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RetroGradientBackground()

                if metrics.isIPad {
                    StageSpotlightOverlay()
                }

                VStack(spacing: 0) {
                    // Header buttons
                    headerButtons

                    if metrics.isIPad {
                        iPadContent
                    } else {
                        iPhoneContent
                    }
                }
                .padding(.top, max(geo.safeAreaInsets.top, 50) + 8)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, 20))
                .padding(.horizontal)
                .frame(maxWidth: metrics.homeMaxWidth, maxHeight: .infinity, alignment: .top)
                .frame(maxWidth: .infinity)
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

    // MARK: - iPad "Studio Lobby" Layout

    private var iPadContent: some View {
        VStack(spacing: 0) {
            Spacer()

            // Centered branding block
            VStack(spacing: 16) {
                // App icon with retro glow
                Image("AppIconImage")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: metrics.appIconSize, height: metrics.appIconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    .shadow(color: Color("NeonPink").opacity(0.6), radius: 30)
                    .shadow(color: Color("ElectricBlue").opacity(0.4), radius: 40)

                VStack(spacing: 10) {
                    Text("RETROTRIVIA")
                        .font(.custom("PressStart2P-Regular", size: metrics.titleFontSize))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("NeonPink"), Color("HotMagenta")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color("NeonPink").opacity(0.8), radius: 8)
                        .shadow(color: Color("NeonPink").opacity(0.4), radius: 12)

                    Text("80s Music Challenge")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("ElectricBlue"))
                        .shadow(color: Color("ElectricBlue").opacity(0.5), radius: 4)
                }

                // Scrolling 80s phrases
                Text(retroPhrases[currentPhraseIndex])
                    .font(.system(size: 24, weight: .bold, design: .rounded))
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

                if gameState.highScorePosition > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color("NeonYellow"))
                        Text("High Score: \(gameState.highScorePosition)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("NeonYellow"))
                            .shadow(color: Color("NeonYellow").opacity(0.6), radius: 6)
                    }
                }
            }

            Spacer()
                .frame(maxHeight: 40)

            // Three game mode "stage door" cards side by side
            HStack(spacing: 20) {
                StageDoorCard(
                    title: "PLAY",
                    icon: "play.fill",
                    subtitle: "Race the clock",
                    details: [("clock", "2 min"), ("trophy", "Ranked")],
                    accent: Color("NeonPink"),
                    isHero: true,
                    entranceDelay: 0.1
                ) {
                    audioManager.playSoundEffect(named: "button-tap")
                    questionManager.filterConfig.difficulty = .any
                    questionManager.filterConfig.save()
                    startGame(leaderboardMode: true)
                }

                StageDoorCard(
                    title: "GAUNTLET",
                    icon: "bolt.fill",
                    subtitle: "Survive or fail",
                    details: [("heart.fill", "3 lives"), ("infinity", "No clock")],
                    accent: Color("ElectricBlue"),
                    entranceDelay: 0.2
                ) {
                    audioManager.playSoundEffect(named: "button-tap")
                    showDifficultyPicker = true
                }

                StageDoorCard(
                    title: "PASS &\nPLAY",
                    icon: "mic.fill",
                    subtitle: "Challenge friends",
                    details: [("person.2.fill", "2-4"), ("wifi.slash", "Local")],
                    accent: Color("NeonYellow"),
                    entranceDelay: 0.3
                ) {
                    audioManager.playSoundEffect(named: "button-tap")
                    activeSheet = .passAndPlaySetup
                }
            }
            .padding(.horizontal, 40)

            Spacer()

            // EQ bars as stage floor decoration
            EqualizerBarsView()
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.bottom, 16)
        }
    }

    // MARK: - iPhone Layout (unchanged)

    private var iPhoneContent: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                if gameState.highScorePosition > 0 {
                    VStack(spacing: 8) {
                        Text("High Score")
                            .retroBody()
                            .opacity(0.8)
                        Text("\(gameState.highScorePosition)")
                            .retroHeading()
                    }
                    .padding(.top, 8)
                }

                VStack(spacing: 12) {
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

                    GameModeCard(
                        "Gauntlet",
                        details: [("heart.fill", "3 lives"), ("infinity", "No clock")],
                        accent: Color("ElectricBlue")
                    ) {
                        audioManager.playSoundEffect(named: "button-tap")
                        showDifficultyPicker = true
                    }

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
            }
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Header Buttons

    private var headerButtons: some View {
        HStack(spacing: 12) {
            Spacer()

            // Music toggle button
            Button(action: {
                audioManager.playSoundEffect(named: "music-toggle")
                audioManager.isMusicEnabled.toggle()
            }) {
                Image(systemName: audioManager.isMusicEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                    .font(.system(size: metrics.headerIconFont))
                    .foregroundStyle(audioManager.isMusicEnabled ? Color("NeonPink") : Color.white.opacity(0.4))
                    .frame(width: metrics.headerIconFrame, height: metrics.headerIconFrame)
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
                        .font(.system(size: metrics.headerIconFont))
                        .foregroundStyle(Color("NeonYellow"))
                        .frame(width: metrics.headerIconFrame, height: metrics.headerIconFrame)
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
                        .font(.system(size: metrics.headerIconFont))
                        .foregroundStyle(Color("NeonYellow"))
                        .frame(width: metrics.headerIconFrame, height: metrics.headerIconFrame)
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
                    .font(.system(size: metrics.headerIconFont))
                    .foregroundStyle(Color("NeonPink"))
                    .frame(width: metrics.headerIconFrame, height: metrics.headerIconFrame)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .sensoryFeedback(.impact(weight: .light), trigger: activeSheet == .settings)
        }
        .padding(.bottom, 16)
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
    @Environment(\.horizontalSizeClass) private var sizeClass
    let title: String
    var subtitle: String? = nil
    let details: [(icon: String, text: String)]
    let accent: Color
    var isHero: Bool = false
    let action: () -> Void

    private var isIPad: Bool { sizeClass == .regular }

    init(_ title: String, subtitle: String? = nil, details: [(icon: String, text: String)], accent: Color, isHero: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
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
                    .frame(width: isIPad ? 5 : 4)
                    .shadow(color: accent.opacity(0.9), radius: 6)
                    .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: isIPad ? 8 : 6) {
                    Text(title)
                        .font(.system(size: isIPad ? 30 : 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: isIPad ? 18 : 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    HStack(spacing: isIPad ? 18 : 14) {
                        ForEach(0..<details.count, id: \.self) { i in
                            Label(details[i].text, systemImage: details[i].icon)
                                .font(.system(size: isIPad ? 17 : 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(accent.opacity(isHero ? 1.0 : 0.8))
                        }
                    }
                }
                .padding(.leading, isIPad ? 24 : 16)

                Spacer()
            }
            .padding(.horizontal, isIPad ? 20 : 16)
            .padding(.vertical, isIPad ? 28 : 18)
            .background(isHero ? accent.opacity(0.1) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: isIPad ? 16 : 14))
            .overlay(
                RoundedRectangle(cornerRadius: isIPad ? 16 : 14)
                    .strokeBorder(accent.opacity(isHero ? 0.5 : 0.25), lineWidth: isHero ? 1.5 : 1)
            )
            .shadow(color: accent.opacity(isHero ? 0.3 : 0.12), radius: isHero ? 10 : 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Stage Door Card (iPad "Game Show" mode selector)

private struct StageDoorCard: View {
    let title: String
    let icon: String
    let subtitle: String
    let details: [(icon: String, text: String)]
    let accent: Color
    var isHero: Bool = false
    var entranceDelay: Double = 0
    let action: () -> Void

    @State private var appeared = false
    @State private var glowPhase: CGFloat = 0

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Spacer()

                // Large icon with neon glow
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(accent)
                    .shadow(color: accent.opacity(0.8), radius: 16)
                    .shadow(color: accent.opacity(0.4), radius: 24)

                // Title
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                // Detail pills
                VStack(spacing: 8) {
                    ForEach(0..<details.count, id: \.self) { i in
                        Label(details[i].text, systemImage: details[i].icon)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(accent.opacity(0.9))
                    }
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isHero ? accent.opacity(0.1) : Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isHero
                            ? LinearGradient(
                                colors: [accent, accent.opacity(0.3 + glowPhase * 0.4), accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [accent.opacity(0.3), accent.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: isHero ? 2 : 1.5
                    )
            )
            .shadow(color: accent.opacity(isHero ? 0.4 : 0.15), radius: isHero ? 16 : 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .scaleEffect(appeared ? 1.0 : 0.85)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(entranceDelay)) {
                appeared = true
            }
            if isHero {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(entranceDelay + 0.6)) {
                    glowPhase = 1.0
                }
            }
        }
    }
}

// MARK: - Equalizer Bars (iPad-only decoration)

private struct EqualizerBarsView: View {
    @State private var barHeights: [CGFloat] = Array(repeating: 0.3, count: 8)

    private let barColors: [Color] = [
        Color("NeonPink"), Color("ElectricBlue"),
        Color("NeonPink"), Color("ElectricBlue"),
        Color("NeonPink"), Color("ElectricBlue"),
        Color("NeonPink"), Color("ElectricBlue")
    ]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColors[index])
                    .frame(width: 6, height: 60 * barHeights[index])
                    .shadow(color: barColors[index].opacity(0.6), radius: 4)
                    .frame(height: 60, alignment: .bottom)
            }
        }
        .onAppear {
            animateBars()
        }
    }

    private func animateBars() {
        for i in 0..<8 {
            let duration = Double.random(in: 0.4...0.8)
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true).delay(Double(i) * 0.05)) {
                barHeights[i] = CGFloat.random(in: 0.3...1.0)
            }
        }
    }
}

// MARK: - Difficulty Picker Overlay

private struct DifficultyPickerOverlay: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onSelect: (Difficulty) -> Void
    let onCancel: () -> Void

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

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
                                .font(.system(size: metrics.isIPad ? 24 : 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text(subtitle)
                                .font(.system(size: metrics.isIPad ? 15 : 12, weight: .regular, design: .rounded))
                                .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                        }
                        .padding(.horizontal, metrics.isIPad ? 40 : 32)
                        .padding(.vertical, metrics.isIPad ? 18 : 14)
                        .frame(minWidth: metrics.isIPad ? 320 : 260)
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
            .frame(maxWidth: metrics.difficultyPickerMaxWidth)
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
