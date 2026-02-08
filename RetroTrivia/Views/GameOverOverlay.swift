//
//  GameOverOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let onComplete: () -> Void

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "clock.badge.xmark")
                    .font(.system(size: 72))
                    .foregroundStyle(Color("NeonPink"))
                    .shadow(color: Color("NeonPink"), radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)

                Text("TIME'S UP!")
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

                RetroButton("Back to Menu", variant: .primary) {
                    onComplete()
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
    GameOverOverlay(score: 12) {
        print("dismissed")
    }
}
