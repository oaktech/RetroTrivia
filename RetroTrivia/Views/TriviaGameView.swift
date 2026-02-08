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
    let onAnswer: (Bool) -> Void

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

    private let countdownTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

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
                // Game timer bar at top
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

            // Overlays
            if showCelebration {
                CelebrationOverlay {
                    handleOverlayComplete(isCorrect: true)
                }
            }

            if showWrong {
                WrongAnswerOverlay {
                    handleOverlayComplete(isCorrect: false)
                }
            }

            if showTimeout {
                TimeoutOverlay {
                    handleOverlayComplete(isCorrect: false)
                }
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTapTrigger)
        .sensoryFeedback(.success, trigger: correctAnswerTrigger)
        .sensoryFeedback(.error, trigger: wrongAnswerTrigger)
        .onAppear {
            if gameState.gameSettings.timerEnabled {
                timeRemaining = Double(gameState.gameSettings.timerDuration)
                timerIsActive = true
            }
        }
        .onReceive(countdownTimer) { _ in
            guard timerIsActive, !hasAnswered else { return }
            if timeRemaining > 0.1 {
                timeRemaining -= 0.1
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
    }

    @ViewBuilder
    private func answerButton(index: Int) -> some View {
        Button(action: {
            handleAnswer(index)
        }) {
            Text(question.options[index])
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(textColor(for: index))
                .multilineTextAlignment(.center)
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
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

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
            .frame(height: 6)

            Text(formattedGameTime(remaining))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
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

        let isCorrect = index == question.correctIndex

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

        if index == question.correctIndex {
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

        if index == question.correctIndex {
            return .green.opacity(0.7)
        } else if index == selectedIndex {
            return .red.opacity(0.7)
        }

        return Color("RetroPurple").opacity(0.3)
    }

    private func borderColor(for index: Int) -> Color {
        if !hasAnswered {
            return Color("ElectricBlue")
        }

        if index == question.correctIndex {
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
