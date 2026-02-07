//
//  GameMapView.swift
//  RetroTrivia
//

import SwiftUI

struct GameMapView: View {
    @Environment(GameState.self) var gameState
    @Environment(AudioManager.self) var audioManager
    let onBackTapped: () -> Void

    @State private var questions: [TriviaQuestion] = []
    @State private var currentQuestion: TriviaQuestion?
    @State private var hasPlayedOnce = false

    private let maxLevel = 50
    private let nodeSpacing: CGFloat = 100

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
                                                        level <= gameState.currentPosition ? Color("ElectricBlue") : Color.white.opacity(0.2),
                                                        level - 1 <= gameState.currentPosition ? Color("ElectricBlue") : Color.white.opacity(0.2)
                                                    ],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                            .frame(width: 3, height: nodeSpacing - 60)
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
        }
        .fullScreenCover(item: $currentQuestion) { question in
            TriviaGameView(question: question) { isCorrect in
                handleAnswer(isCorrect: isCorrect)
            }
        }
        .onAppear {
            loadQuestions()
        }
    }

    private var header: some View {
        HStack {
            Button(action: {
                audioManager.playMenuMusic()
                onBackTapped()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .retroBody()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Spacer()

            if gameState.currentPosition > 0 {
                VStack(spacing: 4) {
                    Text("Position")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(gameState.currentPosition)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("NeonYellow"))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
        }
        .padding()
    }

    private var playButton: some View {
        VStack(spacing: 8) {
            RetroButton(hasPlayedOnce ? "Next Question" : "Play Trivia", variant: .primary) {
                startTrivia()
            }
            .disabled(questions.isEmpty)
            .padding(.horizontal)

            if questions.isEmpty {
                Text("Loading questions...")
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
        questions = TriviaQuestion.loadFromBundle()
        print("DEBUG: Loaded \(questions.count) questions")
        if questions.isEmpty {
            print("DEBUG: WARNING - No questions loaded!")
        }
    }

    private func startTrivia() {
        guard !questions.isEmpty else {
            print("DEBUG: ERROR - No questions available")
            return
        }

        let selectedQuestion = questions.randomElement()
        print("DEBUG: Selected question: \(selectedQuestion?.question ?? "nil")")

        guard let selectedQuestion = selectedQuestion else {
            print("DEBUG: ERROR - Failed to select random question")
            return
        }

        currentQuestion = selectedQuestion
    }

    private func handleAnswer(isCorrect: Bool) {
        print("DEBUG: Answer was \(isCorrect ? "correct" : "wrong")")

        hasPlayedOnce = true

        if isCorrect {
            gameState.incrementPosition()
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
}
