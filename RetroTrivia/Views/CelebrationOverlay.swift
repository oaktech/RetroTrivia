//
//  CelebrationOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct CelebrationOverlay: View {
    let onComplete: () -> Void

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Confetti particles
            ForEach(0..<60, id: \.self) { index in
                ConfettiPiece(index: index, isAnimating: isAnimating)
            }

            // "CORRECT!" text
            VStack(spacing: 20) {
                Text("CORRECT!")
                    .font(.system(size: 64, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("NeonYellow")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink"), radius: 20)
                    .shadow(color: Color("NeonYellow"), radius: 20)
                    .scaleEffect(isAnimating ? 1.2 : 0.5)
                    .opacity(isAnimating ? 1 : 0)

                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("NeonYellow"))
                    .shadow(color: Color("NeonYellow"), radius: 10)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }

            // Auto-dismiss after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let isAnimating: Bool

    @State private var yOffset: CGFloat = -100
    @State private var xOffset: CGFloat = 0
    @State private var rotation: Double = 0

    private let colors: [Color] = [
        Color("NeonPink"),
        Color("ElectricBlue"),
        Color("NeonYellow"),
        Color("HotMagenta")
    ]

    var body: some View {
        let color = colors[index % colors.count]
        let size = CGFloat.random(in: 8...16)

        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color, radius: 4)
            .rotationEffect(.degrees(rotation))
            .offset(x: xOffset, y: yOffset)
            .onAppear {
                let startX = CGFloat.random(in: -200...200)
                let endX = startX + CGFloat.random(in: -50...50)
                let delay = Double.random(in: 0...0.3)

                xOffset = startX

                withAnimation(
                    .linear(duration: 2.0)
                    .delay(delay)
                ) {
                    yOffset = UIScreen.main.bounds.height + 100
                    xOffset = endX
                }

                withAnimation(
                    .linear(duration: 1.0)
                    .repeatForever(autoreverses: false)
                    .delay(delay)
                ) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    CelebrationOverlay {
        print("Celebration complete")
    }
}
