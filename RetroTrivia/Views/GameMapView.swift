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

    private let gameTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum MovementDirection {
        case none
        case climbing
        case falling
    }

    private let maxLevel = 25
    private let nodeSpacing: CGFloat = 100

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
        let fraction = gameTimeRemaining / Double(gameState.gameSettings.gameTimerDuration)
        if fraction > 0.5 { return Color("ElectricBlue") }
        if fraction > 0.25 { return Color("NeonYellow") }
        return Color("NeonPink")
    }

    private var gameTimerDisplay: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(gameTimerColor)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gameTimerColor)
                        .frame(width: geo.size.width * (gameTimeRemaining / Double(gameState.gameSettings.gameTimerDuration)))
                        .animation(.linear(duration: 1), value: gameTimeRemaining)
                }
            }
            .frame(height: 6)

            Text(formattedTime(gameTimeRemaining))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(gameTimerColor)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    private func formattedTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Progressive Intensity Helpers

    private func intensityMultiplier(for level: Int) -> Double {
        // Intensity increases every 3 levels (creates distinct tiers)
        let tier = Double(level / 3)
        let maxTier = Double(25 / 3) // 8 tiers total (0-8)
        return tier / maxTier
    }

    private func lineWidth(for level: Int) -> CGFloat {
        let baseWidth: CGFloat = 2
        let maxWidth: CGFloat = 10
        let intensity = intensityMultiplier(for: level)
        return baseWidth + (maxWidth - baseWidth) * intensity
    }

    private func lineColor(for level: Int) -> Color {
        let intensity = intensityMultiplier(for: level)

        // First transition at tier 2 (0.25), then every 2 tiers (0.5, 0.75)
        if intensity < 0.25 {
            return Color("ElectricBlue")
        } else if intensity < 0.5 {
            return Color("NeonPink")
        } else {
            return Color("HotMagenta")
        }
    }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 0) {
                // Header with Back button and score
                header

                // Scrollable map
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Add top padding
                            Color.clear.frame(height: 100)

                            // Map nodes (reversed to show bottom-to-top)
                            ForEach((0...maxLevel).reversed(), id: \.self) { level in
                                VStack(spacing: 0) {
                                    MapNodeView(
                                        levelIndex: level,
                                        isCurrentPosition: level == gameState.currentPosition,
                                        currentPosition: gameState.currentPosition,
                                        isAnimatingTarget: animatingNodeLevel == level
                                    )
                                    .id(level)

                                    // Connecting line (except for the last node)
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
                                                // Flash effect overlay
                                                Rectangle()
                                                    .fill(Color.white)
                                                    .opacity(isAnimatingLine ? lineFlashIntensity : 0)
                                                    .frame(width: lineWidth(for: level), height: 30)
                                            )
                                            .shadow(
                                                color: isAnimatingLine ? Color("NeonYellow") : .clear,
                                                radius: isAnimatingLine ? 10 * lineFlashIntensity : 0
                                            )
                                            .drawingGroup()
                                    }
                                }
                            }

                            // Add bottom padding
                            Color.clear.frame(height: 100)
                        }
                    }
                    .onChange(of: gameState.currentPosition) { oldValue, newValue in
                        // Dramatic camera movement based on direction
                        let isClimbing = newValue > oldValue
                        let isFalling = newValue < oldValue

                        if isClimbing || isFalling {
                            // First: Quick movement with overshoot
                            let overshootTarget = isClimbing ? min(newValue + 2, maxLevel) : max(newValue - 2, 0)

                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                proxy.scrollTo(overshootTarget, anchor: .center)
                            }

                            // Then: Settle back to actual position
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                        } else {
                            // Normal scroll for initial positioning
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(newValue, anchor: .center)
                            }
                        }
                    }
                    .onAppear {
                        // Store proxy and scroll to current position
                        scrollProxy = proxy
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(gameState.currentPosition, anchor: .center)
                        }
                    }
                }

                // Play button at bottom
                playButton
            }

            // Level up overlay
            if showLevelUp {
                LevelUpOverlay(newTier: levelUpTier) {
                    showLevelUp = false
                }
            }

            // Game over overlay
            if showGameOver {
                GameOverOverlay(score: gameState.currentPosition, reason: gameOverReason) {
                    audioManager.playMenuMusic()
                    onBackTapped()
                }
            }
        }
        .onReceive(gameTimer) { _ in
            guard gameTimerActive else { return }
            if gameTimeRemaining > 0 {
                gameTimeRemaining -= 1
            } else {
                handleGameOver(reason: .timerExpired)
            }
        }
        .fullScreenCover(item: $currentQuestion) { question in
            TriviaGameView(
                question: question,
                gameTimeRemaining: gameState.gameSettings.gameTimerEnabled ? gameTimeRemaining : nil,
                gameTimerDuration: Double(gameState.gameSettings.gameTimerDuration),
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
                // Snap effect: start slightly larger, then spring to normal
                questionCardScale = 1.15
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    questionCardScale = 1.0
                }
            }
        }
        .onAppear {
            loadQuestions()
            if gameState.gameSettings.gameTimerEnabled {
                gameTimeRemaining = Double(gameState.gameSettings.gameTimerDuration)
                // Don't start timer yet - wait for "Play Trivia" button
            }
        }
    }

    private func handleGameOver(reason: GameOverOverlay.Reason = .timerExpired) {
        gameTimerActive = false
        showAutoAdvance = false
        currentQuestion = nil
        audioManager.playSoundEffect(named: "wrong-buzzer")
        gameOverReason = reason
        showGameOver = true
        Task {
            await gameCenterManager.submitScore(gameState.currentPosition)
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

                    // Correct answers indicator
                    if gameState.currentPosition > 0 {
                        ZStack {
                            VStack(spacing: 4) {
                                Text("Correct")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.7))
                                Text("\(gameState.currentPosition)")
                                    .font(.title2)
                                    .fontWeight(.bold)
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
            if gameState.gameSettings.gameTimerEnabled {
                gameTimerDisplay
            }

            // Lives display row
            if gameState.gameSettings.livesEnabled {
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
            // Auto-advance progress bar
            if showAutoAdvance {
                // Single continuous gradient line burning from both ends
                GeometryReader { geometry in
                    ZStack {
                        // Background track
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        // Single continuous gradient line
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
                                // Mask that burns from outside edges toward center
                                HStack(spacing: 0) {
                                    Spacer()

                                    // Center portion (what remains visible as edges burn away)
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
            } else if !hasPlayedOnce {
                // Initial play button
                RetroButton("Play Trivia", variant: .primary) {
                    startTrivia()
                }
                .disabled(isLoadingQuestions || questionManager.questionPool.isEmpty)
                .padding(.horizontal)
                .padding(.vertical, 20)
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
        }
    }

    private func startTrivia() {
        guard let question = questionManager.getNextQuestion() else {
            print("DEBUG: No questions available")
            return
        }

        // Start game timer on first question
        if gameState.gameSettings.gameTimerEnabled && !gameTimerActive {
            gameTimerActive = true
        }

        // Play button tap sound
        audioManager.playSoundEffect(named: "button-tap")

        print("DEBUG: Selected question: \(question.question)")
        questionManager.markQuestionAsked(question.id)
        currentQuestion = question
    }

    private func handleAnswer(isCorrect: Bool) {
        print("DEBUG: Answer was \(isCorrect ? "correct" : "wrong")")

        hasPlayedOnce = true
        var didLevelUp = false

        let oldPosition = gameState.currentPosition

        if isCorrect {
            let oldTier = gameState.currentPosition / 3
            gameState.incrementPosition()
            let newTier = gameState.currentPosition / 3

            // Trigger climbing animation (line above and target node above)
            animateClimbing(from: oldPosition, to: gameState.currentPosition)

            print("DEBUG: Position \(oldPosition) -> \(gameState.currentPosition), Tier \(oldTier) -> \(newTier)")

            // Show level-up overlay when reaching a new tier (every 3 levels)
            if newTier > oldTier {
                didLevelUp = true
                print("DEBUG: Tier crossed! Showing level-up overlay...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.levelUpTier = newTier
                    self.showLevelUp = true
                }
            }
        } else {
            gameState.decrementPosition()

            // Trigger falling animation (line below and target node below)
            animateFalling(from: oldPosition, to: gameState.currentPosition)

            // Check lives
            if gameState.gameSettings.livesEnabled {
                gameState.livesRemaining -= 1
                if gameState.livesRemaining <= 0 {
                    currentQuestion = nil
                    handleGameOver(reason: .livesExhausted)
                    return
                }
            }
        }

        // Clear current question to dismiss the sheet
        currentQuestion = nil

        // Start auto-advance immediately for fluid flow
        startAutoAdvance(extendedDuration: didLevelUp)
    }

    private func animateClimbing(from: Int, to: Int) {
        // Animate the line going UP (the line from 'from' to 'to')
        animatingLineLevel = to
        animatingNodeLevel = to

        // Flash animation for line
        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            lineFlashIntensity = 0.6
        }

        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.lineFlashIntensity = 0.0
            self.animatingLineLevel = nil
            self.animatingNodeLevel = nil
        }
    }

    private func animateFalling(from: Int, to: Int) {
        // Animate the line going DOWN (the line from 'from' to 'to')
        animatingLineLevel = from
        animatingNodeLevel = to

        // Flash animation for line (red-tinted for falling)
        withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
            lineFlashIntensity = 0.4
        }

        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.lineFlashIntensity = 0.0
            self.animatingLineLevel = nil
            self.animatingNodeLevel = nil
        }
    }

    private func startAutoAdvance(extendedDuration: Bool = false) {
        // Reset progress
        autoAdvanceProgress = 1.0
        showAutoAdvance = true

        // Use extended duration for level-up celebration, normal duration otherwise
        let duration: Double = extendedDuration ? 2.5 : 1.0

        // Animate progress bar collapsing
        withAnimation(.linear(duration: duration)) {
            autoAdvanceProgress = 0.0
        }

        // Auto-load next question after duration completes
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if self.showAutoAdvance {
                self.loadNextQuestion()
            }
        }
    }

    private func loadNextQuestion() {
        showAutoAdvance = false
        autoAdvanceProgress = 1.0

        // Small delay for visual snap effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.startTrivia()
        }
    }
}

#Preview {
    GameMapView(onBackTapped: {})
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
        .environment(GameCenterManager.shared)
}
