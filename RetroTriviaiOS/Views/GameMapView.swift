//
//  GameMapView.swift
//  RetroTrivia
//

import SwiftUI
import Combine

struct GameMapView: View {
    @Environment(GameState.self) var gameState
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    @Environment(GameCenterManager.self) var gameCenterManager
    @Environment(BadgeManager.self) var badgeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onBackTapped: () -> Void

    @State private var currentQuestion: TriviaQuestion?
    @State private var hasPlayedOnce = false
    @State private var showLevelUp = false
    @State private var levelUpTier = 0
    @State private var isLoadingQuestions = false
    @State private var showAutoAdvance = false
    @State private var autoAdvanceProgress: CGFloat = 1.0
    @State private var questionCardScale: CGFloat = 1.0
    @State private var animatingLineLevel: Int? = nil
    @State private var animatingNodeLevel: Int? = nil
    @State private var lineFlashIntensity: CGFloat = 0.0
    @State private var scrollProxy: ScrollViewProxy? = nil
    @State private var movementDirection: MovementDirection = .none
    @State private var scoreAnimationScale: CGFloat = 1.0
    @State private var showScoreChange: Bool = false
    @State private var scoreChangeValue: Int = 0
    @State private var scoreChangeOffset: CGFloat = 0
    @State private var scoreChangeOpacity: CGFloat = 1.0
    @State private var gameTimeRemaining: Double = 0
    @State private var gameTimerActive = false
    @State private var showGameOver = false
    @State private var gameOverReason: GameOverOverlay.Reason = .timerExpired
    @State private var urgencyPulse: Bool = false

    // Badge system
    @State private var currentStreak: Int = 0
    #if DEBUG
    @State private var showDebugBadgePanel = false
    #endif
    @State private var sessionBadges: [Badge] = []
    @State private var badgeToastQueue: [Badge] = []
    @State private var showBadgeToast: Bool = false
    @State private var activeBadgeToast: Badge? = nil

    private let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum MovementDirection {
        case none
        case climbing
        case falling
    }

    private let maxLevel = 25

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    private var currentTier: Int {
        gameState.currentPosition / 3
    }

    private var tierColor: Color {
        let intensity = Double(currentTier) / 8.0
        if intensity < 0.4 {
            return Color("ElectricBlue")
        } else if intensity < 0.7 {
            return Color("NeonPink")
        } else {
            return Color("HotMagenta")
        }
    }

    // MARK: - Game Timer Helpers

    private var gameTimerColor: Color {
        let fraction = gameTimeRemaining / Double(GameSettings.leaderboardDuration)
        if fraction > 0.5 { return Color("ElectricBlue") }
        if fraction > 0.25 { return Color("NeonYellow") }
        return Color("NeonPink")
    }

    private var gameTimerDisplay: some View {
        HStack(spacing: 12) {
            Image(systemName: urgencyLevel == .critical ? "exclamationmark.circle.fill" : "clock")
                .font(.system(size: urgencyLevel == .none ? 14 : 16, weight: .semibold))
                .foregroundStyle(gameTimerColor)
                .scaleEffect(urgencyScale)
                .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gameTimerColor)
                        .frame(width: geo.size.width * (gameTimeRemaining / Double(GameSettings.leaderboardDuration)))
                        .animation(.linear(duration: 1), value: gameTimeRemaining)
                }
            }
            .frame(height: urgencyLevel == .critical ? 8 : 6)

            Text(formattedTime(gameTimeRemaining))
                .font(.custom("Orbitron-Bold", size: urgencyLevel == .none ? 13 : 16))
                .monospacedDigit()
                .foregroundStyle(gameTimerColor)
                .scaleEffect(urgencyScale)
                .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, urgencyLevel != .none ? 4 : 0)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(urgencyVignetteColor.opacity(urgencyLevel != .none ? 0.1 : 0))
                .animation(.easeInOut(duration: 0.5), value: urgencyLevel != .none)
        )
    }

    private func formattedTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // Urgency level based on time remaining
    private enum UrgencyLevel {
        case none, moderate, high, critical
    }

    private var urgencyLevel: UrgencyLevel {
        guard gameState.gameSettings.leaderboardMode && gameTimerActive else { return .none }
        if gameTimeRemaining <= 10 { return .critical }
        if gameTimeRemaining <= 20 { return .high }
        if gameTimeRemaining <= 30 { return .moderate }
        return .none
    }

    private var urgencyVignetteOpacity: Double {
        switch urgencyLevel {
        case .none: return 0
        case .moderate: return 0.15
        case .high: return 0.25
        case .critical: return 0.4
        }
    }

    private var urgencyVignetteColor: Color {
        switch urgencyLevel {
        case .none, .moderate: return Color("NeonPink")
        case .high: return Color.orange
        case .critical: return Color.red
        }
    }

    private var urgencyScale: CGFloat {
        guard urgencyPulse else { return 1.0 }
        switch urgencyLevel {
        case .none: return 1.0
        case .moderate: return 1.05
        case .high: return 1.1
        case .critical: return 1.15
        }
    }

    // MARK: - Progressive Intensity Helpers

    private func intensityMultiplier(for level: Int) -> Double {
        let tier = Double(level / 3)
        let maxTier = Double(25 / 3)
        return tier / maxTier
    }

    private func lineWidth(for level: Int) -> CGFloat {
        let baseWidth: CGFloat = 2
        let maxWidth: CGFloat = 6
        let intensity = intensityMultiplier(for: level)
        return baseWidth + (maxWidth - baseWidth) * intensity
    }

    private func lineColor(for level: Int) -> Color {
        let intensity = intensityMultiplier(for: level)
        if intensity < 0.25 {
            return Color("ElectricBlue")
        } else if intensity < 0.5 {
            return Color("NeonPink")
        } else {
            return Color("HotMagenta")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RetroGradientBackground()

                if metrics.isIPad {
                    StageSpotlightOverlay()
                }

                if !hasPlayedOnce {
                    if isLoadingQuestions {
                        ProgressView()
                            .tint(Color("NeonPink"))
                    }
                }

                if metrics.isIPad {
                    // iPad: "The Game Board" — snaking grid + podium bar
                    VStack(spacing: 0) {
                        iPadMapHeader
                        Spacer()
                        SnakeGridMapView(
                            currentPosition: gameState.currentPosition,
                            maxLevel: maxLevel
                        )
                        .padding(.horizontal, 40)
                        .frame(maxHeight: geometry.size.height * 0.6)
                        Spacer()
                        iPadPodiumBar
                        iPadAutoAdvanceBar
                    }
                    .opacity(hasPlayedOnce ? 1 : 0)
                } else {
                    // iPhone: Original layout
                    VStack(spacing: 0) {
                        header
                        mapContent(geometry: geometry)
                        playButton
                    }
                    .opacity(hasPlayedOnce ? 1 : 0)
                }

                // Level up overlay
                if showLevelUp {
                    LevelUpOverlay(newTier: levelUpTier) {
                        showLevelUp = false
                    }
                }

                // Game over overlay
                if showGameOver {
                    GameOverOverlay(
                        score: gameState.currentPosition,
                        reason: gameOverReason,
                        newBadges: sessionBadges,
                        onPlayAgain: {
                            playAgain()
                        }
                    ) {
                        audioManager.playMenuMusic()
                        onBackTapped()
                    }
                }

                // Badge toast
                if let toastBadge = activeBadgeToast {
                    VStack {
                        BadgeToastView(badge: toastBadge, isVisible: showBadgeToast)
                            .padding(.top, 8)
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    .zIndex(100)
                }

                // Urgency vignette overlay — uses GeometryReader instead of UIScreen
                if urgencyLevel != .none {
                    let vignetteSize = min(geometry.size.width, geometry.size.height)
                    Rectangle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.clear,
                                    Color.clear,
                                    urgencyVignetteColor.opacity(urgencyVignetteOpacity * (urgencyPulse ? 1.2 : 0.8))
                                ],
                                center: .center,
                                startRadius: vignetteSize * 0.3,
                                endRadius: vignetteSize * 0.8
                            )
                        )
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)
                }
            }
        }
        .onReceive(gameTimer) { _ in
            guard gameTimerActive else { return }
            if gameTimeRemaining > 0 {
                gameTimeRemaining -= 1

                if urgencyLevel != .none {
                    let shouldPulse: Bool
                    switch urgencyLevel {
                    case .critical:
                        shouldPulse = true
                    case .high:
                        shouldPulse = Int(gameTimeRemaining) % 2 == 0
                    case .moderate:
                        shouldPulse = Int(gameTimeRemaining) % 3 == 0
                    case .none:
                        shouldPulse = false
                    }

                    if shouldPulse {
                        urgencyPulse = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            urgencyPulse = false
                        }
                    }
                }
            } else {
                handleGameOver(reason: .timerExpired)
            }
        }
        .fullScreenCover(item: $currentQuestion) { question in
            TriviaGameView(
                question: question,
                gameTimeRemaining: gameState.gameSettings.leaderboardMode ? gameTimeRemaining : nil,
                gameTimerDuration: Double(GameSettings.leaderboardDuration),
                livesRemaining: gameState.gameSettings.livesEnabled ? gameState.livesRemaining : nil,
                startingLives: gameState.gameSettings.startingLives,
                onAnswer: { isCorrect in
                    handleAnswer(isCorrect: isCorrect)
                },
                onQuit: {
                    currentQuestion = nil
                    audioManager.playMenuMusic()
                    onBackTapped()
                }
            )
            .scaleEffect(questionCardScale)
            .onAppear {
                questionCardScale = 1.15
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    questionCardScale = 1.0
                }
            }
        }
        .onAppear {
            loadQuestions()
            if gameState.gameSettings.leaderboardMode {
                gameTimeRemaining = Double(GameSettings.leaderboardDuration)
            }
        }
        #if DEBUG
        .sheet(isPresented: $showDebugBadgePanel) {
            DebugBadgePanelView(onUnlock: enqueueBadgeToasts)
                .environment(badgeManager)
        }
        #endif
    }

    // MARK: - iPad Stats Sidebar

    @ViewBuilder
    private var iPadStatsSidebar: some View {
        VStack(spacing: 20) {
            // Tier badge
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(tierColor.opacity(0.2))
                        .stroke(tierColor.opacity(0.6), lineWidth: 2)

                    VStack(spacing: 4) {
                        Text("Tier \(currentTier + 1)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(tierColor)
                        Text(tierName(for: currentTier))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(tierColor.opacity(0.8))
                    }
                    .padding(.vertical, 12)
                }
                .frame(height: 70)
                .shadow(color: tierColor.opacity(0.4), radius: 8)
            }

            // Streak
            VStack(spacing: 6) {
                Text("Streak")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(currentStreak >= 5 ? Color("NeonPink") : .white.opacity(0.5))
                    Text("\(currentStreak)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(currentStreak >= 5 ? Color("NeonPink") : .white)
                }
            }

            // Accuracy
            if gameState.currentPosition > 0 || currentStreak > 0 {
                VStack(spacing: 6) {
                    Text("Accuracy")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(gameState.currentPosition)")
                        .font(.custom("Orbitron-Bold", size: 18))
                        .monospacedDigit()
                        .foregroundStyle(Color("NeonYellow"))
                }
            }

            // Lives (gauntlet mode)
            if gameState.gameSettings.livesEnabled {
                VStack(spacing: 6) {
                    Text("Lives")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 4) {
                        ForEach(0..<gameState.gameSettings.startingLives, id: \.self) { i in
                            Image(systemName: i < gameState.livesRemaining ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundStyle(Color("NeonPink"))
                                .shadow(color: Color("NeonPink").opacity(i < gameState.livesRemaining ? 0.6 : 0), radius: 4)
                        }
                    }
                }
            }

            // Recent badges
            if !sessionBadges.isEmpty {
                VStack(spacing: 6) {
                    Text("Badges")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                    ForEach(sessionBadges.suffix(3)) { badge in
                        HStack(spacing: 6) {
                            Image(systemName: badge.iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(badge.iconColor))
                            Text(badge.title)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.black.opacity(0.15))
    }

    // MARK: - iPad Game Board Header

    private var iPadMapHeader: some View {
        HStack {
            Button(action: {
                audioManager.playSoundEffect(named: "back-button")
                audioManager.playMenuMusic()
                onBackTapped()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                    Text("Quit")
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.red.opacity(0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.15))
                        .stroke(.red.opacity(0.4), lineWidth: 1)
                )
            }

            Spacer()

            // Center: Level + Tier name
            VStack(spacing: 2) {
                Text("LEVEL \(gameState.currentPosition) of \(maxLevel)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tracking(1)
                Text(tierName(for: currentTier).uppercased())
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(tierColor)
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(tierColor.opacity(0.1))
                    .stroke(tierColor.opacity(0.3), lineWidth: 1)
            )
            #if DEBUG
            .onLongPressGesture { showDebugBadgePanel = true }
            #endif

            Spacer()

            // Right: LED clock or game timer
            if gameState.gameSettings.leaderboardMode {
                LEDClockTimerView(timeRemaining: gameTimeRemaining, totalTime: Double(GameSettings.leaderboardDuration))
                    .scaleEffect(0.55)
                    .frame(width: 140, height: 56)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - iPad Podium Stats Bar

    private var iPadPodiumBar: some View {
        PodiumBar(items: {
            var items: [PodiumItem] = []

            items.append(PodiumItem(
                icon: "flame.fill",
                value: "\(currentStreak)",
                label: "Streak",
                color: currentStreak >= 5 ? Color("NeonPink") : Color("ElectricBlue"),
                isHighlighted: currentStreak >= 5
            ))

            if gameState.currentPosition > 0 {
                items.append(PodiumItem(
                    icon: "target",
                    value: "\(gameState.currentPosition)",
                    label: "Correct",
                    color: Color("NeonYellow")
                ))
            }

            if gameState.gameSettings.livesEnabled {
                let livesStr = String(repeating: "\u{2665}", count: gameState.livesRemaining)
                items.append(PodiumItem(
                    icon: "heart.fill",
                    value: livesStr.isEmpty ? "0" : livesStr,
                    label: "Lives",
                    color: Color("NeonPink"),
                    isHighlighted: gameState.livesRemaining <= 1
                ))
            }

            if !sessionBadges.isEmpty {
                items.append(PodiumItem(
                    icon: "medal.fill",
                    value: "x\(sessionBadges.count)",
                    label: "Badges",
                    color: Color("NeonYellow")
                ))
            }

            return items
        }())
    }

    // MARK: - iPad Auto-Advance Bar

    private var iPadAutoAdvanceBar: some View {
        VStack(spacing: 0) {
            if showAutoAdvance {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("NeonPink"), Color("ElectricBlue"), Color("HotMagenta")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 6)
                            .mask(
                                HStack(spacing: 0) {
                                    Spacer()
                                    Rectangle()
                                        .frame(width: geometry.size.width * autoAdvanceProgress)
                                    Spacer()
                                }
                            )
                    }
                    .frame(height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .frame(height: 6)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .transition(.opacity)
            }

            if isLoadingQuestions {
                Text("Loading questions...")
                    .retroBody()
                    .opacity(0.6)
                    .padding(.bottom, 12)
            } else if questionManager.questionPool.isEmpty {
                Text("No questions available")
                    .retroBody()
                    .opacity(0.6)
                    .padding(.bottom, 12)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private func tierName(for tier: Int) -> String {
        switch tier {
        case 0: return "Beginner"
        case 1: return "Rising Star"
        case 2: return "On Fire"
        case 3: return "Hot Streak"
        case 4: return "Supercharged"
        case 5: return "Elite"
        case 6: return "Champion"
        case 7: return "Legendary"
        case 8: return "Ultimate"
        default: return "Level \(tier + 1)"
        }
    }

    // MARK: - Map Content

    @ViewBuilder
    private func mapContent(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 100)

                    if metrics.isIPad {
                        // iPad: Zigzag path with curved connections
                        ForEach((0...maxLevel).reversed(), id: \.self) { level in
                            let xOffset = sin(Double(level) * .pi / 3.0) * Double(metrics.mapZigzagAmplitude)
                            VStack(spacing: 0) {
                                MapNodeView(
                                    levelIndex: level,
                                    isCurrentPosition: level == gameState.currentPosition,
                                    currentPosition: gameState.currentPosition,
                                    isAnimatingTarget: animatingNodeLevel == level,
                                    sizeMultiplier: metrics.mapNodeSizeMultiplier
                                )
                                .id(level)
                                .offset(x: CGFloat(xOffset))

                                if level > 0 {
                                    let isAnimatingLine = animatingLineLevel == level
                                    let nextXOffset = sin(Double(level - 1) * .pi / 3.0) * Double(metrics.mapZigzagAmplitude)
                                    ZigzagConnector(
                                        fromX: CGFloat(xOffset),
                                        toX: CGFloat(nextXOffset),
                                        height: 40 * metrics.mapLineHeightMultiplier,
                                        lineWidth: lineWidth(for: level),
                                        color: level <= gameState.currentPosition ? lineColor(for: level) : Color.white.opacity(0.2),
                                        flashIntensity: isAnimatingLine ? lineFlashIntensity : 0,
                                        shadowColor: isAnimatingLine
                                            ? Color("NeonYellow")
                                            : (level <= gameState.currentPosition ? lineColor(for: level).opacity(0.5) : .clear),
                                        shadowRadius: isAnimatingLine
                                            ? 10 * lineFlashIntensity
                                            : (level <= gameState.currentPosition ? lineWidth(for: level) * 1.5 : 0)
                                    )
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        // iPhone: Straight vertical path (original)
                        ForEach((0...maxLevel).reversed(), id: \.self) { level in
                            VStack(spacing: 0) {
                                MapNodeView(
                                    levelIndex: level,
                                    isCurrentPosition: level == gameState.currentPosition,
                                    currentPosition: gameState.currentPosition,
                                    isAnimatingTarget: animatingNodeLevel == level
                                )
                                .id(level)

                                if level > 0 {
                                    let isAnimatingLine = animatingLineLevel == level
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    level <= gameState.currentPosition ? lineColor(for: level) : Color.white.opacity(0.2),
                                                    level - 1 <= gameState.currentPosition ? lineColor(for: level - 1) : Color.white.opacity(0.2)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: lineWidth(for: level), height: 30)
                                        .padding(.vertical, 8)
                                        .overlay(
                                            Rectangle()
                                                .fill(Color.white)
                                                .opacity(isAnimatingLine ? lineFlashIntensity : 0)
                                                .frame(width: lineWidth(for: level), height: 30)
                                        )
                                        .shadow(
                                            color: isAnimatingLine
                                                ? Color("NeonYellow")
                                                : (level <= gameState.currentPosition ? lineColor(for: level).opacity(0.5) : .clear),
                                            radius: isAnimatingLine
                                                ? 10 * lineFlashIntensity
                                                : (level <= gameState.currentPosition ? lineWidth(for: level) * 1.5 : 0)
                                        )
                                        .drawingGroup()
                                }
                            }
                        }
                    }

                    Color.clear.frame(height: 100)
                }
            }
            .onChange(of: gameState.currentPosition) { oldValue, newValue in
                let isClimbing = newValue > oldValue
                let isFalling = newValue < oldValue

                if isClimbing || isFalling {
                    let overshootTarget = isClimbing ? min(newValue + 2, maxLevel) : max(newValue - 2, 0)

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        proxy.scrollTo(overshootTarget, anchor: .center)
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(newValue, anchor: .center)
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.scrollTo(gameState.currentPosition, anchor: .center)
                }
            }
        }
    }

    private func playAgain() {
        showGameOver = false
        currentStreak = 0
        sessionBadges = []
        badgeToastQueue = []
        showBadgeToast = false
        activeBadgeToast = nil
        gameState.resetGame()
        questionManager.resetSession()
        if gameState.gameSettings.leaderboardMode {
            gameTimeRemaining = Double(GameSettings.leaderboardDuration)
            gameTimerActive = false
        }
        loadQuestions()
    }

    private func handleGameOver(reason: GameOverOverlay.Reason = .timerExpired) {
        gameTimerActive = false
        showAutoAdvance = false
        currentQuestion = nil
        audioManager.playSoundEffect(named: "wrong-buzzer")
        gameOverReason = reason

        let newBadges = badgeManager.checkBadges(
            position: gameState.currentPosition,
            streak: currentStreak,
            livesRemaining: gameState.livesRemaining,
            isLeaderboardMode: gameState.gameSettings.leaderboardMode,
            isGameOver: true,
            difficulty: questionManager.filterConfig.difficulty
        )
        enqueueBadgeToasts(newBadges)

        showGameOver = true
        if gameState.gameSettings.leaderboardMode {
            Task {
                await gameCenterManager.submitScore(gameState.currentPosition)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    audioManager.playSoundEffect(named: "back-button")
                    audioManager.playMenuMusic()
                    onBackTapped()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                        Text("Quit")
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red.opacity(0.15))
                            .stroke(.red.opacity(0.4), lineWidth: 1)
                    )
                }

                Spacer()

                HStack(spacing: 16) {
                    // Tier indicator
                    VStack(spacing: 4) {
                        Text("Level")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(tierColor)
                            Text("\(currentTier + 1)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(tierColor)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(tierColor.opacity(0.15))
                            .stroke(tierColor.opacity(0.4), lineWidth: 1)
                    )
                    #if DEBUG
                    .onLongPressGesture { showDebugBadgePanel = true }
                    #endif

                    // Correct answers indicator
                    if gameState.currentPosition > 0 {
                        ZStack {
                            VStack(spacing: 4) {
                                Text("Correct")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("\(gameState.currentPosition)")
                                    .font(.custom("Orbitron-Bold", size: 20))
                                    .monospacedDigit()
                                    .foregroundStyle(Color("NeonYellow"))
                                    .contentTransition(.numericText())
                            }
                            .scaleEffect(scoreAnimationScale)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)

                            // Floating score change indicator
                            if showScoreChange {
                                Text(scoreChangeValue > 0 ? "+\(scoreChangeValue)" : "\(scoreChangeValue)")
                                    .font(.title)
                                    .fontWeight(.black)
                                    .foregroundStyle(scoreChangeValue > 0 ? Color("NeonPink") : Color.red)
                                    .shadow(color: scoreChangeValue > 0 ? Color("NeonPink") : Color.red, radius: 8)
                                    .offset(y: scoreChangeOffset)
                                    .opacity(scoreChangeOpacity)
                            }
                        }
                        .onChange(of: gameState.currentPosition) { oldValue, newValue in
                            let change = newValue - oldValue
                            showScoreChange = false
                            scoreChangeOffset = 0
                            scoreChangeOpacity = 1.0
                            scoreAnimationScale = 1.0
                            scoreChangeValue = change
                            showScoreChange = true
                            if change > 0 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                    scoreAnimationScale = 1.3
                                }
                                withAnimation(.easeOut(duration: 0.8)) {
                                    scoreChangeOffset = -40
                                    scoreChangeOpacity = 0.0
                                }
                            } else if change < 0 {
                                withAnimation(.easeInOut(duration: 0.15).repeatCount(2, autoreverses: true)) {
                                    scoreAnimationScale = 0.9
                                }
                                withAnimation(.easeOut(duration: 0.8)) {
                                    scoreChangeOffset = 40
                                    scoreChangeOpacity = 0.0
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    self.scoreAnimationScale = 1.0
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                self.showScoreChange = false
                            }
                        }
                    }
                }
            }

            // Game timer full-width row
            if gameState.gameSettings.leaderboardMode {
                gameTimerDisplay
            }

            // Lives display row (iPhone only — iPad shows in sidebar)
            if gameState.gameSettings.livesEnabled && !metrics.isIPad {
                HStack(spacing: 6) {
                    ForEach(0..<gameState.gameSettings.startingLives, id: \.self) { i in
                        Image(systemName: i < gameState.livesRemaining ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundStyle(Color("NeonPink"))
                            .shadow(color: Color("NeonPink").opacity(i < gameState.livesRemaining ? 0.6 : 0), radius: 4)
                    }
                }
            }
        }
        .padding()
    }

    private var playButton: some View {
        VStack(spacing: 0) {
            if showAutoAdvance {
                GeometryReader { geometry in
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("NeonPink"), Color("ElectricBlue"), Color("HotMagenta")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 6)
                            .mask(
                                HStack(spacing: 0) {
                                    Spacer()
                                    Rectangle()
                                        .frame(width: geometry.size.width * autoAdvanceProgress)
                                    Spacer()
                                }
                            )
                    }
                    .frame(height: 6)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .frame(height: 6)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .transition(.opacity)
            }

            if isLoadingQuestions {
                Text("Loading questions...")
                    .retroBody()
                    .opacity(0.6)
                    .padding(.bottom, 20)
            } else if questionManager.questionPool.isEmpty {
                Text("No questions available")
                    .retroBody()
                    .opacity(0.6)
                    .padding(.bottom, 20)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(
            LinearGradient(
                colors: [
                    Color("RetroPurple").opacity(0.95),
                    Color("RetroPurple")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func loadQuestions() {
        Task {
            isLoadingQuestions = true
            await questionManager.loadQuestions()
            isLoadingQuestions = false
            print("DEBUG: \(questionManager.getPoolStatus())")

            if !questionManager.questionPool.isEmpty {
                startTrivia()
            }
        }
    }

    private func startTrivia() {
        guard let question = questionManager.getNextQuestion() else {
            print("DEBUG: No questions available")
            return
        }

        if gameState.gameSettings.leaderboardMode && !gameTimerActive {
            gameTimerActive = true
            badgeManager.recordGameStarted()
            let newBadges = badgeManager.checkBadges(
                position: gameState.currentPosition,
                streak: currentStreak,
                livesRemaining: gameState.livesRemaining,
                isLeaderboardMode: true,
                isGameOver: false,
                difficulty: questionManager.filterConfig.difficulty
            )
            enqueueBadgeToasts(newBadges)
        } else if !gameState.gameSettings.leaderboardMode && !hasPlayedOnce {
            badgeManager.recordGameStarted()
            let newBadges = badgeManager.checkBadges(
                position: gameState.currentPosition,
                streak: currentStreak,
                livesRemaining: gameState.livesRemaining,
                isLeaderboardMode: false,
                isGameOver: false,
                difficulty: questionManager.filterConfig.difficulty
            )
            enqueueBadgeToasts(newBadges)
        }

        audioManager.playSoundEffect(named: "button-tap")

        print("DEBUG: Selected question: \(question.question)")
        questionManager.markQuestionAsked(question.id)
        currentQuestion = question
    }

    // MARK: - Badge Toast Queue

    private func enqueueBadgeToasts(_ badges: [Badge]) {
        guard !badges.isEmpty else { return }
        sessionBadges.append(contentsOf: badges)
        badgeToastQueue.append(contentsOf: badges)
        if !showBadgeToast {
            showNextToast()
        }
    }

    private func showNextToast() {
        guard !badgeToastQueue.isEmpty else {
            activeBadgeToast = nil
            return
        }
        let next = badgeToastQueue.removeFirst()
        activeBadgeToast = next
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { self.showBadgeToast = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation { self.showBadgeToast = false }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            self.showNextToast()
        }
    }

    private func handleAnswer(isCorrect: Bool) {
        print("DEBUG: Answer was \(isCorrect ? "correct" : "wrong")")

        hasPlayedOnce = true
        var didLevelUp = false

        let oldPosition = gameState.currentPosition

        if isCorrect {
            currentStreak += 1
            let oldTier = gameState.currentPosition / 3
            gameState.incrementPosition()
            let newTier = gameState.currentPosition / 3

            animateClimbing(from: oldPosition, to: gameState.currentPosition)

            print("DEBUG: Position \(oldPosition) -> \(gameState.currentPosition), Tier \(oldTier) -> \(newTier)")

            let newBadges = badgeManager.checkBadges(
                position: gameState.currentPosition,
                streak: currentStreak,
                livesRemaining: gameState.livesRemaining,
                isLeaderboardMode: gameState.gameSettings.leaderboardMode,
                isGameOver: false,
                difficulty: questionManager.filterConfig.difficulty
            )
            enqueueBadgeToasts(newBadges)

            if newTier > oldTier {
                didLevelUp = true
                print("DEBUG: Tier crossed! Showing level-up overlay...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.levelUpTier = newTier
                    self.showLevelUp = true
                }
            }
        } else {
            currentStreak = 0
            gameState.decrementPosition()

            animateFalling(from: oldPosition, to: gameState.currentPosition)

            if gameState.gameSettings.livesEnabled {
                gameState.livesRemaining -= 1
                if gameState.livesRemaining <= 0 {
                    currentQuestion = nil
                    handleGameOver(reason: .livesExhausted)
                    return
                }
            }
        }

        currentQuestion = nil
        startAutoAdvance(extendedDuration: didLevelUp)
    }

    private func animateClimbing(from: Int, to: Int) {
        animatingLineLevel = to
        animatingNodeLevel = to

        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            lineFlashIntensity = 0.6
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.lineFlashIntensity = 0.0
            self.animatingLineLevel = nil
            self.animatingNodeLevel = nil
        }
    }

    private func animateFalling(from: Int, to: Int) {
        animatingLineLevel = from
        animatingNodeLevel = to

        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            lineFlashIntensity = 0.4
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.lineFlashIntensity = 0.0
            self.animatingLineLevel = nil
            self.animatingNodeLevel = nil
        }
    }

    private func startAutoAdvance(extendedDuration: Bool = false) {
        autoAdvanceProgress = 1.0
        showAutoAdvance = true

        let duration: Double = extendedDuration ? 2.5 : 1.0

        withAnimation(.linear(duration: duration)) {
            autoAdvanceProgress = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.showAutoAdvance {
                self.loadNextQuestion()
            }
        }
    }

    private func loadNextQuestion() {
        showAutoAdvance = false
        autoAdvanceProgress = 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startTrivia()
        }
    }
}

// MARK: - Zigzag Connector (iPad curved path between nodes)

private struct ZigzagConnector: View {
    let fromX: CGFloat
    let toX: CGFloat
    let height: CGFloat
    let lineWidth: CGFloat
    let color: Color
    var flashIntensity: CGFloat = 0
    var shadowColor: Color = .clear
    var shadowRadius: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let startPoint = CGPoint(x: size.width / 2 + fromX, y: 0)
            let endPoint = CGPoint(x: size.width / 2 + toX, y: size.height)
            let controlPoint = CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: size.height / 2
            )
            path.move(to: startPoint)
            path.addQuadCurve(to: endPoint, control: controlPoint)

            context.stroke(path, with: .color(color), lineWidth: lineWidth)

            if flashIntensity > 0 {
                context.stroke(path, with: .color(.white.opacity(Double(flashIntensity))), lineWidth: lineWidth)
            }
        }
        .frame(height: height)
        .shadow(color: shadowColor, radius: shadowRadius)
    }
}

#Preview {
    GameMapView(onBackTapped: {})
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
        .environment(GameCenterManager.shared)
        .environment(BadgeManager.shared)
}
