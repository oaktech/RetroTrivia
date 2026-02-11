//
//  PassAndPlayMapView.swift
//  RetroTrivia
//

import SwiftUI

struct PassAndPlayMapView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    let session: PassAndPlaySession
    let onDone: () -> Void

    @State private var currentQuestion: TriviaQuestion?
    @State private var showHandoff: Bool = true
    @State private var showFinalStandings: Bool = false
    @State private var animatingNodeLevel: Int? = nil
    @State private var isLoadingQuestions: Bool = false
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let maxLevel = 25
    private let nodeSpacing: CGFloat = 100

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 0) {
                // Header
                header

                // Scrollable map
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            Color.clear.frame(height: 100)

                            // Map nodes with player dots
                            ForEach((0...maxLevel).reversed(), id: \.self) { level in
                                VStack(spacing: 0) {
                                    MapNodeView(
                                        levelIndex: level,
                                        isCurrentPosition: false,
                                        currentPosition: 0,
                                        isAnimatingTarget: animatingNodeLevel == level,
                                        playerDots: getPlayerDotsForLevel(level)
                                    )
                                    .id(level)

                                    // Connecting line
                                    if level > 0 {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 2, height: 30)
                                            .padding(.vertical, 8)
                                    }
                                }
                            }

                            Color.clear.frame(height: 100)
                        }
                    }
                    .onChange(of: session.maxPosition) { _, newMaxPosition in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(newMaxPosition, anchor: .center)
                        }
                    }
                    .onAppear {
                        scrollProxy = proxy
                    }
                }
            }

            // Handoff overlay
            if showHandoff && !showFinalStandings {
                HandoffView(
                    playerName: session.currentPlayer.name,
                    playerColor: session.currentPlayer.color,
                    onReady: {
                        showHandoff = false
                        loadNextQuestion()
                    }
                )
                .transition(.opacity)
            }

            // Final standings
            if showFinalStandings {
                FinalStandingsView(
                    session: session,
                    onPlayAgain: { playAgain() },
                    onHome: { onDone() }
                )
                .transition(.opacity)
            }

            // Question sheet
            if let question = currentQuestion {
                TriviaGameView(
                    question: question,
                    gameTimeRemaining: nil,
                    livesRemaining: nil,
                    onAnswer: { isCorrect in
                        handleAnswer(isCorrect: isCorrect)
                    },
                    onQuit: {
                        currentQuestion = nil
                        audioManager.playMenuMusic()
                        onDone()
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            audioManager.playGameplayMusic()
            // Load questions asynchronously
            Task {
                await loadQuestionsPool()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    audioManager.playSoundEffect(named: "back-button")
                    audioManager.playMenuMusic()
                    onDone()
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

                // Current player indicator
                VStack(spacing: 4) {
                    Text("Current Player")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    HStack(spacing: 8) {
                        Circle()
                            .fill(session.currentPlayer.color)
                            .frame(width: 12, height: 12)
                        Text(session.currentPlayer.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(session.currentPlayer.color.opacity(0.15))
                        .stroke(session.currentPlayer.color.opacity(0.4), lineWidth: 1)
                )
            }

            // Players standings (mini)
            HStack(spacing: 8) {
                ForEach(session.players, id: \.id) { player in
                    VStack(spacing: 2) {
                        Circle()
                            .fill(player.color)
                            .frame(width: 8, height: 8)
                        Text(player.name)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                        Text("\(player.position)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(player.color)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color("RetroPurple").opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
    }

    // MARK: - Helpers

    private func getPlayerDotsForLevel(_ level: Int) -> [Color] {
        session.players
            .filter { $0.position == level }
            .map { $0.color }
    }

    private func loadQuestionsPool() async {
        isLoadingQuestions = true
        await questionManager.loadQuestions()
        isLoadingQuestions = false
    }

    private func loadNextQuestion() {
        // Find next unanswered question from the pool (respecting session's asked questions)
        if let question = questionManager.questionPool.first(where: { !session.askedQuestionIDs.contains($0.id) }) {
            session.askedQuestionIDs.insert(question.id)
            questionManager.markQuestionAsked(question.id)  // Also mark in question manager
            currentQuestion = question
        } else {
            // No more questions - game over
            session.isGameOver = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showFinalStandings = true
            }
        }
    }

    private func handleAnswer(isCorrect: Bool) {
        let oldPosition = session.currentPlayer.position

        if isCorrect {
            session.players[session.currentPlayerIndex].position += 1
            session.players[session.currentPlayerIndex].correctAnswers += 1
            animatingNodeLevel = session.currentPlayer.position
        } else {
            session.players[session.currentPlayerIndex].position = max(0, session.currentPlayer.position - 1)
        }

        session.players[session.currentPlayerIndex].questionsAnswered += 1

        // Check win condition
        if session.checkWinCondition() {
            session.isGameOver = true
            // Clear current question to dismiss sheet
            currentQuestion = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showFinalStandings = true
            }
        } else {
            // Advance to next player and show handoff immediately (before dismissing question)
            session.advanceToNextPlayer()
            showHandoff = true
            // Then clear current question after handoff is showing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentQuestion = nil
            }
        }
    }

    private func playAgain() {
        // Reset session
        session.players = session.players.map { player in
            var p = player
            p.position = 0
            p.questionsAnswered = 0
            p.correctAnswers = 0
            return p
        }
        session.currentPlayerIndex = 0
        session.isGameOver = false
        session.askedQuestionIDs.removeAll()

        showFinalStandings = false
        showHandoff = true

        // Reset question manager
        questionManager.resetSession()

        // Reload questions
        Task {
            await loadQuestionsPool()
        }
    }
}

#Preview {
    let session = PassAndPlaySession(
        playerNames: ["Sarah", "Mike"],
        roundLimit: .fixed(5),
        difficulty: .any
    )
    PassAndPlayMapView(session: session, onDone: {})
        .environment(AudioManager.shared)
        .environment(QuestionManager())
}
