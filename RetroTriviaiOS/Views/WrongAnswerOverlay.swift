//
//  WrongAnswerOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct WrongAnswerOverlay: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    let correctAnswer: String
    let onComplete: () -> Void

    @State private var isAnimating = false
    @State private var shakeOffset: CGFloat = 0

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            // iPad spotlight backdrop
            if metrics.isIPad {
                RadialGradient(
                    colors: [Color.red.opacity(0.06), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80 * metrics.overlayIconScale))
                    .foregroundStyle(.red)
                    .shadow(color: .red, radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: shakeOffset)

                Text("WRONG")
                    .font(.system(size: 56 * metrics.overlayTextScale, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .red, radius: 15)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: shakeOffset)

                VStack(spacing: 6) {
                    Text("The answer was:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(correctAnswer)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                        .shadow(color: .green.opacity(0.6), radius: 6)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .scaleEffect(isAnimating ? 1.0 : 0.5)
                .opacity(isAnimating ? 1 : 0)
            }
            .frame(maxWidth: metrics.overlayMaxWidth)
        }
        .onAppear {
            audioManager.playSoundEffect(named: "wrong-buzzer")

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }

            withAnimation(
                .easeInOut(duration: 0.1)
                .repeatCount(4, autoreverses: true)
            ) {
                shakeOffset = 10
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    WrongAnswerOverlay(correctAnswer: "Thriller") {
        print("Wrong answer overlay complete")
    }
    .environment(AudioManager.shared)
}
