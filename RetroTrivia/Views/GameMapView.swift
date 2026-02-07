//
//  GameMapView.swift
//  RetroTrivia
//

import SwiftUI

struct GameMapView: View {
    @Environment(GameState.self) var gameState
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    let onBackTapped: () -> Void

    @State private var currentQuestion: TriviaQuestion?
    @State private var hasPlayedOnce = false
    @State private var showQuitConfirmation = false
    @State private var showLevelUp = false
    @State private var levelUpTier = 0
    @State private var isLoadingQuestions = false

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
                                        currentPosition: gameState.currentPosition
                                    )
                                    .id(level)

                                    // Connecting line (except for the last node)
                                    if level > 0 {
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
                                            .frame(width: lineWidth(for: level), height: nodeSpacing - 60)
                                            .drawingGroup()
                                    }
                                }
                            }

                            // Add bottom padding
                            Color.clear.frame(height: 100)
                        }
                    }
                    .onChange(of: gameState.currentPosition) { oldValue, newValue in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                    .onAppear {
                        // Scroll to current position on appear
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
        }
        .fullScreenCover(item: $currentQuestion) { question in
            TriviaGameView(question: question) { isCorrect in
                handleAnswer(isCorrect: isCorrect)
            }
        }
        .alert("Quit Game?", isPresented: $showQuitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Quit", role: .destructive) {
                audioManager.playMenuMusic()
                onBackTapped()
            }
        } message: {
            Text("Are you sure you want to quit? Your current position will be saved.")
        }
        .onAppear {
            loadQuestions()
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                audioManager.playSoundEffect(named: "back-button")
                showQuitConfirmation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                    Text("Quit Game")
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
                    VStack(spacing: 4) {
                        Text("Correct")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text("\(gameState.currentPosition)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("NeonYellow"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
    }

    private var playButton: some View {
        VStack(spacing: 8) {
            RetroButton(hasPlayedOnce ? "Next Question" : "Play Trivia", variant: .primary) {
                startTrivia()
            }
            .disabled(isLoadingQuestions || questionManager.questionPool.isEmpty)
            .padding(.horizontal)

            if isLoadingQuestions {
                Text("Loading questions...")
                    .retroBody()
                    .opacity(0.6)
            } else if questionManager.questionPool.isEmpty {
                Text("No questions available")
                    .retroBody()
                    .opacity(0.6)
            }
        }
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [
                    Color("RetroPurple").opacity(0.95),
                    Color("RetroPurple")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
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

        // Play button tap sound
        audioManager.playSoundEffect(named: "button-tap")

        print("DEBUG: Selected question: \(question.question)")
        questionManager.markQuestionAsked(question.id)
        currentQuestion = question
    }

    private func handleAnswer(isCorrect: Bool) {
        print("DEBUG: Answer was \(isCorrect ? "correct" : "wrong")")

        hasPlayedOnce = true

        if isCorrect {
            let oldTier = gameState.currentPosition / 3
            gameState.incrementPosition()
            let newTier = gameState.currentPosition / 3

            print("DEBUG: Position \(gameState.currentPosition - 1) -> \(gameState.currentPosition), Tier \(oldTier) -> \(newTier)")

            // Show level-up overlay when reaching a new tier (every 3 levels)
            if newTier > oldTier {
                print("DEBUG: Tier crossed! Showing level-up overlay...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.levelUpTier = newTier
                    self.showLevelUp = true
                }
            }
        } else {
            gameState.decrementPosition()
        }

        // Clear current question to dismiss the sheet
        currentQuestion = nil
    }
}

#Preview {
    GameMapView(onBackTapped: {})
        .environment(GameState())
        .environment(AudioManager.shared)
        .environment(QuestionManager())
}
