//
//  PassAndPlayMapView.swift
//  RetroTrivia
//

import SwiftUI

struct PassAndPlayMapView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(QuestionManager.self) var questionManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let session: PassAndPlaySession
    let onDone: () -> Void

    @State private var currentQuestion: TriviaQuestion?
    @State private var showHandoff: Bool = true
    @State private var showFinalStandings: Bool = false
    @State private var animatingNodeLevel: Int? = nil
    @State private var isLoadingQuestions: Bool = false
    @State private var scrollProxy: ScrollViewProxy? = nil

    private let maxLevel = 25

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            if metrics.isIPad {
                StageSpotlightOverlay()
            }

            VStack(spacing: 0) {
                // Header
                header

                if metrics.isIPad {
                    // iPad: "The Arena" — snaking grid + player podium
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            Spacer()
                            SnakeGridMapView(
                                currentPosition: 0,
                                maxLevel: maxLevel,
                                playerDots: buildPlayerDotsMap(),
                                isMultiplayer: true
                            )
                            .padding(.horizontal, 40)
                            .frame(maxHeight: geometry.size.height * 0.65)
                            Spacer()
                            // Player podium bar
                            iPadPlayerPodiumBar
                        }
                    }
                } else {
                    mapContent
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
            Task {
                await loadQuestionsPool()
            }
        }
    }

    // MARK: - iPad Player Sidebar

    @ViewBuilder
    private var iPadPlayerSidebar: some View {
        VStack(spacing: 16) {
            Text("PLAYERS")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .tracking(2)
                .padding(.top, 8)

            ForEach(session.players, id: \.id) { player in
                let isCurrent = player.id == session.currentPlayer.id
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(player.color)
                            .frame(width: 14, height: 14)
                        Text(player.name)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text("Pos")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(player.position)")
                                .font(.custom("Orbitron-Bold", size: 16))
                                .monospacedDigit()
                                .foregroundStyle(player.color)
                        }
                        VStack(spacing: 2) {
                            Text("Score")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                            Text("\(player.correctAnswers)/\(player.questionsAnswered)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(player.color.opacity(isCurrent ? 0.15 : 0.05))
                        .stroke(player.color.opacity(isCurrent ? 0.6 : 0.2), lineWidth: isCurrent ? 2 : 1)
                )
                .shadow(color: isCurrent ? player.color.opacity(0.4) : .clear, radius: isCurrent ? 8 : 0)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.black.opacity(0.15))
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

            // Players standings (mini) — iPhone only (iPad has sidebar)
            if !metrics.isIPad {
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
        }
        .padding()
    }

    // MARK: - Map Content

    private var mapContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    Color.clear.frame(height: 100)

                    if metrics.isIPad {
                        // iPad: Zigzag path
                        ForEach((0...maxLevel).reversed(), id: \.self) { level in
                            let xOffset = sin(Double(level) * .pi / 3.0) * Double(metrics.mapZigzagAmplitude)
                            VStack(spacing: 0) {
                                MapNodeView(
                                    levelIndex: level,
                                    isCurrentPosition: false,
                                    currentPosition: 0,
                                    isAnimatingTarget: animatingNodeLevel == level,
                                    playerDots: getPlayerDotsForLevel(level),
                                    sizeMultiplier: metrics.mapNodeSizeMultiplier
                                )
                                .id(level)
                                .offset(x: CGFloat(xOffset))

                                if level > 0 {
                                    let nextXOffset = sin(Double(level - 1) * .pi / 3.0) * Double(metrics.mapZigzagAmplitude)
                                    ZigzagConnectorSimple(
                                        fromX: CGFloat(xOffset),
                                        toX: CGFloat(nextXOffset),
                                        height: 40
                                    )
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    } else {
                        // iPhone: Straight path
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

                                if level > 0 {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 2, height: 30)
                                        .padding(.vertical, 8)
                                }
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

    // MARK: - iPad Player Podium Bar

    private var iPadPlayerPodiumBar: some View {
        HStack(spacing: 12) {
            ForEach(session.players, id: \.id) { player in
                PlayerPodiumCard(
                    name: player.name,
                    color: player.color,
                    position: player.position,
                    score: "\(player.correctAnswers)/\(player.questionsAnswered)",
                    isCurrent: player.id == session.currentPlayer.id
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    /// Build a dictionary mapping level positions to player colors for the snake grid.
    private func buildPlayerDotsMap() -> [Int: [Color]] {
        var map: [Int: [Color]] = [:]
        for player in session.players {
            map[player.position, default: []].append(player.color)
        }
        return map
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
        if let question = questionManager.questionPool.first(where: { !session.askedQuestionIDs.contains($0.id) }) {
            session.askedQuestionIDs.insert(question.id)
            questionManager.markQuestionAsked(question.id)
            currentQuestion = question
        } else {
            session.isGameOver = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showFinalStandings = true
            }
        }
    }

    private func handleAnswer(isCorrect: Bool) {
        if isCorrect {
            session.players[session.currentPlayerIndex].position += 1
            session.players[session.currentPlayerIndex].correctAnswers += 1
            animatingNodeLevel = session.currentPlayer.position
        } else {
            session.players[session.currentPlayerIndex].position = max(0, session.currentPlayer.position - 1)
        }

        session.players[session.currentPlayerIndex].questionsAnswered += 1

        if session.checkWinCondition() {
            session.isGameOver = true
            currentQuestion = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showFinalStandings = true
            }
        } else {
            session.advanceToNextPlayer()
            showHandoff = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                currentQuestion = nil
            }
        }
    }

    private func playAgain() {
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

        questionManager.resetSession()

        Task {
            await loadQuestionsPool()
        }
    }
}

// MARK: - Simple Zigzag Connector (for Pass & Play map)

private struct ZigzagConnectorSimple: View {
    let fromX: CGFloat
    let toX: CGFloat
    let height: CGFloat

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
            context.stroke(path, with: .color(.white.opacity(0.2)), lineWidth: 2)
        }
        .frame(height: height)
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
