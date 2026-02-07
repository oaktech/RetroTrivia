//
//  GameMapView.swift
//  RetroTrivia
//

import SwiftUI

struct GameMapView: View {
    @Environment(GameState.self) var gameState
    let onBackTapped: () -> Void

    @State private var questions: [TriviaQuestion] = []
    @State private var currentQuestion: TriviaQuestion?
    @State private var showTriviaGame = false

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                // Header with Back button
                HStack {
                    Button(action: onBackTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .retroBody()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                // Current position display
                VStack(spacing: 20) {
                    Text("Current Position")
                        .retroBody()
                        .opacity(0.8)

                    Text("\(gameState.currentPosition)")
                        .font(.system(size: 72, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("NeonPink"), Color("ElectricBlue")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color("NeonPink").opacity(0.8), radius: 20)

                    if gameState.currentPosition > 0 {
                        Text("High Score: \(gameState.highScorePosition)")
                            .retroSubtitle()
                    }
                }

                Spacer()

                // Play button
                RetroButton("Play Trivia", variant: .primary) {
                    startTrivia()
                }
                .disabled(questions.isEmpty)

                if questions.isEmpty {
                    Text("Loading questions...")
                        .retroBody()
                        .opacity(0.6)
                } else {
                    Text("\(questions.count) questions loaded")
                        .retroBody()
                        .opacity(0.6)
                        .font(.caption)
                }

                Spacer()
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
}
