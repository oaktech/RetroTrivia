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
    let onComplete: () -> Void

    @Environment(GameCenterManager.self) private var gameCenterManager
    @State private var isAnimating = false
    @State private var showLeaderboard = false

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
                    .font(.system(size: 48, weight: .black, design: .rounded))
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
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .foregroundStyle(Color("NeonYellow"))
                        .shadow(color: Color("NeonYellow"), radius: 10)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)

                VStack(spacing: 12) {
                    if gameCenterManager.isAuthenticated {
                        RetroButton("Leaderboard", variant: .secondary) {
                            showLeaderboard = true
                        }
                    }

                    RetroButton("Back to Menu", variant: .primary) {
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
        .sheet(isPresented: $showLeaderboard) {
            GameCenterLeaderboardView()
        }
    }
}

#Preview {
    GameOverOverlay(score: 12) {
        print("dismissed")
    }
    .environment(GameCenterManager.shared)
}
