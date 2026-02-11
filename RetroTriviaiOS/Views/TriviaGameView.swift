//
//  TriviaGameView.swift
//  RetroTrivia
//

import SwiftUI
import Combine

struct TriviaGameView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(GameState.self) var gameState

    let question: TriviaQuestion
    var gameTimeRemaining: Double? = nil
    var gameTimerDuration: Double = 180
    var livesRemaining: Int? = nil
    var startingLives: Int = 3
    let onAnswer: (Bool) -> Void
    var onQuit: (() -> Void)? = nil

    @State private var shuffledOptions: [String] = []
    @State private var shuffledCorrectIndex: Int = 0
    @State private var selectedIndex: Int? = nil
    @State private var hasAnswered = false
    @State private var buttonTapTrigger = 0
    @State private var correctAnswerTrigger = false
    @State private var wrongAnswerTrigger = false
    @State private var showCelebration = false
    @State private var showWrong = false
    @State private var showTimeout = false
    @State private var timeRemaining: Double = 15.0
    @State private var timerIsActive = false
    @State private var urgencyPulse = false
    @State private var lastTickSecond: Int = -1

    private var isShowingOverlay: Bool {
        showCelebration || showWrong || showTimeout
    }

    private let countdownTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    // Urgency level based on game time remaining
    private enum UrgencyLevel {
        case none, moderate, high, critical
    }

    private var urgencyLevel: UrgencyLevel {
        guard let remaining = gameTimeRemaining else { return .none }
        if remaining <= 10 { return .critical }
        if remaining <= 20 { return .high }
        if remaining <= 30 { return .moderate }
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

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color("RetroPurple"),
                    Color("RetroPurple").opacity(0.8),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                // Header with quit button and game timer
                HStack {
                    if let quit = onQuit {
                        Button(action: {
                            audioManager.playSoundEffect(named: "back-button")
                            quit()
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
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)

                // Game timer bar
                if let remaining = gameTimeRemaining {
                    gameTimerBar(remaining: remaining)
                }

                Spacer()

                // Per-question timer
                if gameState.gameSettings.timerEnabled {
                    CountdownTimerView(
                        timeRemaining: timeRemaining,
                        totalTime: Double(gameState.gameSettings.timerDuration)
                    )
                }

                // Lives display
                if let lives = livesRemaining {
                    HStack(spacing: 6) {
                        ForEach(0..<startingLives, id: \.self) { i in
                            Image(systemName: i < lives ? "heart.fill" : "heart")
                                .font(.system(size: 20))
                                .foregroundStyle(Color("NeonPink"))
                        }
                    }
                }

                // Question
                Text(question.question)
                    .retroHeading()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                // Answer buttons in 2x2 grid
                VStack(spacing: 16) {
                    ForEach(0..<2) { row in
                        HStack(spacing: 16) {
                            ForEach(0..<2) { col in
                                let index = row * 2 + col
                                if index < question.options.count {
                                    answerButton(index: index)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }

            // Dim overlay when showing answer feedback
            if isShowingOverlay {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // Overlays
            if showCelebration {
                CelebrationOverlay {
                    handleOverlayComplete(isCorrect: true)
                }
            }

            if showWrong {
                WrongAnswerOverlay(correctAnswer: shuffledOptions.indices.contains(shuffledCorrectIndex) ? shuffledOptions[shuffledCorrectIndex] : question.options[question.correctIndex]) {
                    handleOverlayComplete(isCorrect: false)
                }
            }

            if showTimeout {
                TimeoutOverlay {
                    handleOverlayComplete(isCorrect: false)
                }
            }

            // Urgency vignette overlay (screen edge glow when time is running out)
            if urgencyLevel != .none {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.clear,
                                urgencyVignetteColor.opacity(urgencyVignetteOpacity * (urgencyPulse ? 1.2 : 0.8))
                            ],
                            center: .center,
                            startRadius: UIScreen.main.bounds.width * 0.3,
                            endRadius: UIScreen.main.bounds.width * 0.8
                        )
                    )
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTapTrigger)
        .sensoryFeedback(.success, trigger: correctAnswerTrigger)
        .sensoryFeedback(.error, trigger: wrongAnswerTrigger)
        .onAppear {
            // Shuffle answer positions so the correct answer isn't always in the same slot
            let indices = (0..<question.options.count).shuffled()
            shuffledOptions = indices.map { question.options[$0] }
            shuffledCorrectIndex = indices.firstIndex(of: question.correctIndex) ?? 0

            lastTickSecond = -1
            if gameState.gameSettings.timerEnabled {
                timeRemaining = Double(gameState.gameSettings.timerDuration)
                timerIsActive = true
            }
        }
        .onReceive(countdownTimer) { _ in
            guard timerIsActive, !hasAnswered else { return }
            if timeRemaining > 0.1 {
                timeRemaining -= 0.1

                // Tick sound in last 5 seconds
                let currentSecond = Int(ceil(timeRemaining))
                if currentSecond >= 1, currentSecond <= 5, currentSecond != lastTickSecond {
                    lastTickSecond = currentSecond
                    audioManager.playTickSound()
                }
            } else {
                handleTimeout()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            timerIsActive = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            if !hasAnswered && gameState.gameSettings.timerEnabled {
                timerIsActive = true
            }
        }
        .onChange(of: gameTimeRemaining) { oldValue, newValue in
            guard let remaining = newValue else { return }

            // Trigger urgency pulse at thresholds
            let shouldPulse: Bool
            switch urgencyLevel {
            case .critical:
                shouldPulse = true // every second
            case .high:
                shouldPulse = Int(remaining) % 2 == 0 // every 2 seconds
            case .moderate:
                shouldPulse = Int(remaining) % 3 == 0 // every 3 seconds
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
    }

    private static let letterLabels = ["A", "B", "C", "D"]

    @ViewBuilder
    private func answerButton(index: Int) -> some View {
        Button(action: {
            handleAnswer(index)
        }) {
            HStack(spacing: 12) {
                // Letter chip
                Text(Self.letterLabels[index])
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(letterChipColor(for: index))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Answer text
                Text(shuffledOptions.indices.contains(index) ? shuffledOptions[index] : "")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor(for: index))
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(backgroundColor(for: index))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor(for: index), lineWidth: 2)
            )
        }
        .disabled(hasAnswered)
    }

    @ViewBuilder
    private func gameTimerBar(remaining: Double) -> some View {
        let fraction = max(0, min(1, remaining / gameTimerDuration))
        let color: Color = fraction > 0.5 ? Color("ElectricBlue") : fraction > 0.25 ? Color("NeonYellow") : Color("NeonPink")

        HStack(spacing: 10) {
            Image(systemName: urgencyLevel == .critical ? "exclamationmark.circle.fill" : "clock")
                .font(.system(size: urgencyLevel == .none ? 13 : 15, weight: .semibold))
                .foregroundStyle(color)
                .scaleEffect(urgencyScale)
                .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * fraction)
                        .animation(.linear(duration: 1), value: fraction)
                }
            }
            .frame(height: urgencyLevel == .critical ? 8 : 6)

            Text(formattedGameTime(remaining))
                .font(.system(size: urgencyLevel == .none ? 13 : 16, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(color)
                .scaleEffect(urgencyScale)
                .animation(.easeInOut(duration: urgencyLevel == .critical ? 0.3 : 0.5), value: urgencyPulse)
                .frame(width: 45, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, urgencyLevel != .none ? 8 : 0)
        .padding(.top, urgencyLevel == .none ? 8 : 0)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(urgencyVignetteColor.opacity(urgencyLevel != .none ? 0.1 : 0))
                .animation(.easeInOut(duration: 0.5), value: urgencyLevel != .none)
        )
    }

    private func formattedGameTime(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }

    private func handleTimeout() {
        guard !hasAnswered else { return }
        timerIsActive = false
        hasAnswered = true
        wrongAnswerTrigger.toggle()
        showTimeout = true
    }

    private func handleAnswer(_ index: Int) {
        guard !hasAnswered else { return }
        timerIsActive = false

        // Light tap feedback (sound + haptic)
        audioManager.playSoundEffect(named: "button-tap")
        buttonTapTrigger += 1

        selectedIndex = index
        hasAnswered = true

        let isCorrect = index == shuffledCorrectIndex

        // Show appropriate overlay with haptic (overlay handles the sound)
        if isCorrect {
            correctAnswerTrigger.toggle()
            showCelebration = true
        } else {
            wrongAnswerTrigger.toggle()
            showWrong = true
        }
    }

    private func handleOverlayComplete(isCorrect: Bool) {
        // Hide overlays
        showCelebration = false
        showWrong = false
        showTimeout = false

        // Small delay before dismissing to ensure smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onAnswer(isCorrect)
        }
    }

    private func textColor(for index: Int) -> Color {
        if !hasAnswered {
            return .white
        }

        if index == shuffledCorrectIndex {
            return .white
        } else if index == selectedIndex {
            return .white
        }

        return .white.opacity(0.5)
    }

    private func backgroundColor(for index: Int) -> Color {
        if !hasAnswered {
            return Color("RetroPurple").opacity(0.6)
        }

        if index == shuffledCorrectIndex {
            return .green.opacity(0.7)
        } else if index == selectedIndex {
            return .red.opacity(0.7)
        }

        return Color("RetroPurple").opacity(0.3)
    }

    private static let defaultChipColors: [Color] = [
        Color("ElectricBlue"), Color("NeonPink"), Color("NeonYellow"), Color("HotMagenta")
    ]

    private func letterChipColor(for index: Int) -> Color {
        if !hasAnswered {
            return Self.defaultChipColors[index]
        }
        if index == shuffledCorrectIndex {
            return .green
        } else if index == selectedIndex {
            return .red
        }
        return Self.defaultChipColors[index].opacity(0.4)
    }

    private func borderColor(for index: Int) -> Color {
        if !hasAnswered {
            return Color("ElectricBlue")
        }

        if index == shuffledCorrectIndex {
            return .green
        } else if index == selectedIndex {
            return .red
        }

        return Color("ElectricBlue").opacity(0.3)
    }
}

#Preview {
    let sampleQuestion = TriviaQuestion(
        id: "preview",
        question: "Which Michael Jackson album became the best-selling album of all time?",
        options: ["Bad", "Thriller", "Off the Wall", "Dangerous"],
        correctIndex: 1,
        category: "Albums",
        difficulty: "easy"
    )

    return TriviaGameView(question: sampleQuestion) { isCorrect in
        print("Answer: \(isCorrect)")
    }
    .environment(AudioManager.shared)
    .environment(GameState())
}
