//
//  WrongAnswerOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct WrongAnswerOverlay: View {
    let onComplete: () -> Void

    @State private var isAnimating = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.red)
                    .shadow(color: .red, radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: shakeOffset)

                Text("WRONG")
                    .font(.system(size: 56, weight: .black, design: .rounded))
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
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }

            // Shake animation
            withAnimation(
                .easeInOut(duration: 0.1)
                .repeatCount(4, autoreverses: true)
            ) {
                shakeOffset = 10
            }

            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    WrongAnswerOverlay {
        print("Wrong answer overlay complete")
    }
}
