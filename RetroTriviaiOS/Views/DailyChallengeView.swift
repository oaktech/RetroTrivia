//
//  DailyChallengeView.swift
//  RetroTrivia
//

import SwiftUI

struct DailyChallengeView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    @Environment(BadgeManager.self) var badgeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onDone: () -> Void

    @State private var currentQuestion: TriviaQuestion?
    @State private var questionsAnswered = 0
    @State private var correctAnswers = 0
    @State private var currentStreak = 0
    @State private var isLoadingQuestions = false
    @State private var showResult = false
    @State private var questionCardScale: CGFloat = 1.0

    private let totalQuestions = DailyChallengeManager.questionCount

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            if metrics.isIPad {
                StageSpotlightOverlay()
            }

            if showResult {
                resultView
            } else if isLoadingQuestions {
                ProgressView()
                    .tint(Color("NeonPink"))
            } else {
                gameContent
            }
        }
        .fullScreenCover(item: $currentQuestion) { question in
            TriviaGameView(
                question: question,
                gameTimeRemaining: nil,
                gameTimerDuration: nil,
                livesRemaining: nil,
                startingLives: 0,
                onAnswer: { isCorrect in
                    handleAnswer(isCorrect: isCorrect)
                },
                onQuit: {
                    currentQuestion = nil
                    audioManager.playMenuMusic()
                    onDone()
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
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Text("DAILY CHALLENGE")
                    .font(.custom("PressStart2P-Regular", size: metrics.isIPad ? 22 : 16))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("HotMagenta")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink").opacity(0.8), radius: 8)

                Text("Question \(questionsAnswered + 1) of \(totalQuestions)")
                    .font(.system(size: metrics.isIPad ? 18 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("ElectricBlue"))
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color("NeonPink"), Color("ElectricBlue")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(questionsAnswered) / CGFloat(totalQuestions))
                        .animation(.easeInOut(duration: 0.3), value: questionsAnswered)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 40)

            // Stats
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("Correct")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(correctAnswers)")
                        .font(.custom("Orbitron-Bold", size: 24))
                        .foregroundStyle(Color("NeonYellow"))
                }

                VStack(spacing: 4) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(currentStreak >= 3 ? Color("NeonPink") : .white.opacity(0.5))
                        Text("\(currentStreak)")
                            .font(.custom("Orbitron-Bold", size: 24))
                            .foregroundStyle(currentStreak >= 3 ? Color("NeonPink") : .white)
                    }
                }
            }

            Spacer()

            // Waiting state — auto-advance to next question
            Text("Get ready...")
                .retroBody()
                .opacity(0.6)

            Spacer()
        }
        .frame(maxWidth: metrics.overlayMaxWidth)
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("CHALLENGE COMPLETE!")
                .font(.custom("PressStart2P-Regular", size: metrics.isIPad ? 20 : 14))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("NeonPink"), Color("HotMagenta")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: Color("NeonPink").opacity(0.8), radius: 8)
                .multilineTextAlignment(.center)

            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(correctAnswers) / CGFloat(totalQuestions))
                    .stroke(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("ElectricBlue")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(correctAnswers)")
                        .font(.custom("Orbitron-Bold", size: metrics.isIPad ? 48 : 36))
                        .foregroundStyle(Color("NeonYellow"))
                    Text("of \(totalQuestions)")
                        .font(.system(size: metrics.isIPad ? 16 : 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: metrics.isIPad ? 180 : 140, height: metrics.isIPad ? 180 : 140)

            // Streak info
            let dailyManager = DailyChallengeManager.shared
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(Color("NeonPink"))
                    Text("\(dailyManager.currentStreak)-day streak")
                        .font(.system(size: metrics.isIPad ? 20 : 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

                if dailyManager.bestStreak > 1 {
                    Text("Best streak: \(dailyManager.bestStreak) days")
                        .font(.system(size: metrics.isIPad ? 15 : 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                }

                if dailyManager.bestScore > 0 {
                    Text("Best daily score: \(dailyManager.bestScore)/\(totalQuestions)")
                        .font(.system(size: metrics.isIPad ? 15 : 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color("NeonYellow").opacity(0.8))
                }
            }

            Spacer()

            RetroButton("Done", variant: .primary) {
                audioManager.playSoundEffect(named: "button-tap")
                audioManager.playMenuMusic()
                onDone()
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: metrics.overlayMaxWidth)
    }

    // MARK: - Logic

    private func loadQuestions() {
        Task {
            isLoadingQuestions = true
            await questionManager.loadQuestions()
            isLoadingQuestions = false
            audioManager.playGameplayMusic()
            advanceToNextQuestion()
        }
    }

    private func advanceToNextQuestion() {
        guard questionsAnswered < totalQuestions else {
            // Challenge complete
            DailyChallengeManager.shared.recordCompletion(score: correctAnswers)
            NotificationManager.shared.cancelStreakReminder()
            NotificationManager.shared.scheduleStreakReminder(currentStreak: DailyChallengeManager.shared.currentStreak)
            audioManager.playSoundEffect(named: "correct-answer")
            showResult = true
            return
        }

        guard let question = questionManager.getNextQuestion() else { return }
        questionManager.markQuestionAsked(question.id)
        currentQuestion = question
    }

    private func handleAnswer(isCorrect: Bool) {
        questionsAnswered += 1

        if isCorrect {
            correctAnswers += 1
            currentStreak += 1
        } else {
            currentStreak = 0
        }

        currentQuestion = nil

        // Brief delay then advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            advanceToNextQuestion()
        }
    }
}

#Preview {
    DailyChallengeView(onDone: {})
        .environment(AudioManager.shared)
        .environment(QuestionManager())
        .environment(BadgeManager.shared)
}
