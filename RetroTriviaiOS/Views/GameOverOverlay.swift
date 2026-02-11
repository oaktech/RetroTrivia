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
    @State private var isAnimating = false

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

            VStack(spacing: 24) {
                Image(systemName: iconName)
                    .font(.system(size: 72))
                    .foregroundStyle(Color("NeonPink"))
                    .shadow(color: Color("NeonPink"), radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)

                Text(titleText)
                    .font(.custom("PressStart2P-Regular", size: 28))
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

                    Text("\(score)")
                        .font(.custom("Orbitron-Bold", size: 52))
                        .monospacedDigit()
                        .foregroundStyle(Color("NeonYellow"))
                        .shadow(color: Color("NeonYellow"), radius: 10)
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
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }

    }
}

#Preview {
    GameOverOverlay(score: 12, onPlayAgain: { print("play again") }) {
        print("dismissed")
    }
    .environment(GameCenterManager.shared)
}
