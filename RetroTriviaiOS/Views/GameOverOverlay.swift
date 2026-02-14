//
//  GameOverOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct GameOverOverlay: View {
    enum Reason {
        case timerExpired
        case livesExhausted
    }

    let score: Int
    var reason: Reason = .timerExpired
    var newBadges: [Badge] = []
    let onPlayAgain: (() -> Void)?
    let onComplete: () -> Void

    @Environment(GameCenterManager.self) private var gameCenterManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var isAnimating = false
    @State private var displayedScore = 0
    @State private var countUpTimer: Timer?

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    private var titleText: String {
        switch reason {
        case .timerExpired: return "TIME'S UP!"
        case .livesExhausted: return "GAME OVER!"
        }
    }

    private var iconName: String {
        switch reason {
        case .timerExpired: return "clock.badge.xmark"
        case .livesExhausted: return "heart.slash.fill"
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            // iPad spotlight backdrop
            if metrics.isIPad {
                RadialGradient(
                    colors: [Color("NeonPink").opacity(0.08), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 450
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 24) {
                Image(systemName: iconName)
                    .font(.system(size: 72 * metrics.overlayIconScale))
                    .foregroundStyle(Color("NeonPink"))
                    .shadow(color: Color("NeonPink"), radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)

                Text(titleText)
                    .font(.custom("PressStart2P-Regular", size: 28 * metrics.overlayTextScale))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("HotMagenta")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink"), radius: 15)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)

                VStack(spacing: 8) {
                    Text("Final Score")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))

                    Text("\(displayedScore)")
                        .font(.custom("Orbitron-Bold", size: 52 * metrics.overlayTextScale))
                        .monospacedDigit()
                        .foregroundStyle(Color("NeonYellow"))
                        .shadow(color: Color("NeonYellow"), radius: 10)
                        .contentTransition(.numericText())
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)

                // New badges earned this session
                if !newBadges.isEmpty {
                    VStack(spacing: 8) {
                        Text("NEW BADGES")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(Color("NeonYellow"))
                            .tracking(2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(newBadges) { badge in
                                    HStack(spacing: 6) {
                                        Image(systemName: badge.iconName)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(Color(badge.iconColor))
                                        Text(badge.title)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color("NeonYellow"))
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.08))
                                            .stroke(Color("NeonYellow").opacity(0.35), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                }

                VStack(spacing: 12) {
                    if let onPlayAgain {
                        RetroButton("Play Again", variant: .primary) {
                            onPlayAgain()
                        }
                    }

                    if gameCenterManager.isAuthenticated {
                        RetroButton("Leaderboard", variant: .secondary) {
                            GameCenterLeaderboard.show()
                        }
                    }

                    RetroButton("Back to Menu", variant: .secondary) {
                        onComplete()
                    }
                }
                .opacity(isAnimating ? 1 : 0)
                .padding(.top, 8)
            }
            .padding(32)
            .frame(maxWidth: metrics.gameOverMaxWidth)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = true
            }

            guard score > 0 else {
                displayedScore = 0
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let steps = min(score, 60)
                let increment = max(1, score / steps)
                let interval = 1.0 / Double(steps)

                countUpTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
                    let next = displayedScore + increment
                    if next >= score {
                        withAnimation(.default) { displayedScore = score }
                        timer.invalidate()
                    } else {
                        withAnimation(.default) { displayedScore = next }
                    }
                }
            }
        }
        .onDisappear {
            countUpTimer?.invalidate()
            countUpTimer = nil
        }

    }
}

#Preview {
    GameOverOverlay(score: 12, onPlayAgain: { print("play again") }) {
        print("dismissed")
    }
    .environment(GameCenterManager.shared)
}
