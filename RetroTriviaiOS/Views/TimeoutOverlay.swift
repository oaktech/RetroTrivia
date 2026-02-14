//
//  TimeoutOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct TimeoutOverlay: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass

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
                    colors: [Color("NeonYellow").opacity(0.06), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 80 * metrics.overlayIconScale))
                    .foregroundStyle(Color("NeonYellow"))
                    .shadow(color: Color("NeonYellow"), radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.3)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: shakeOffset)

                Text("TIME'S UP!")
                    .font(.system(size: 48 * metrics.overlayTextScale, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonYellow"), .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonYellow"), radius: 15)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(x: shakeOffset)
            }
            .frame(maxWidth: metrics.overlayMaxWidth)
        }
        .onAppear {
            audioManager.playSoundEffect(named: "wrong-buzzer")

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                isAnimating = true
            }

            withAnimation(.easeInOut(duration: 0.1).repeatCount(4, autoreverses: true)) {
                shakeOffset = 10
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}

#Preview {
    TimeoutOverlay {
        print("Timeout overlay complete")
    }
    .environment(AudioManager.shared)
}
