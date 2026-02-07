//
//  TriviaGameView.swift
//  RetroTrivia
//

import SwiftUI

struct TriviaGameView: View {
    let question: TriviaQuestion
    let onAnswer: (Bool) -> Void

    @State private var selectedIndex: Int? = nil
    @State private var hasAnswered = false
    @State private var buttonTapTrigger = 0
    @State private var correctAnswerTrigger = false
    @State private var wrongAnswerTrigger = false

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
                Spacer()

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
        }
        .sensoryFeedback(.impact(weight: .light), trigger: buttonTapTrigger)
        .sensoryFeedback(.success, trigger: correctAnswerTrigger)
        .sensoryFeedback(.error, trigger: wrongAnswerTrigger)
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

    private func handleAnswer(_ index: Int) {
        guard !hasAnswered else { return }

        // Light tap feedback
        buttonTapTrigger += 1

        selectedIndex = index
        hasAnswered = true

        let isCorrect = index == question.correctIndex

        // Trigger appropriate haptic feedback
        if isCorrect {
            correctAnswerTrigger.toggle()
        } else {
            wrongAnswerTrigger.toggle()
        }

        // Delay to show feedback before calling onAnswer
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
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
}
