//
//  LevelUpOverlay.swift
//  RetroTrivia
//

import SwiftUI

struct LevelUpOverlay: View {
    @Environment(AudioManager.self) var audioManager
    let newTier: Int
    let onComplete: () -> Void

    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationDegrees: Double = 0

    private var tierName: String {
        switch newTier {
        case 0: return "Beginner"
        case 1: return "Rising Star"
        case 2: return "On Fire"
        case 3: return "Hot Streak"
        case 4: return "Supercharged"
        case 5: return "Elite"
        case 6: return "Champion"
        case 7: return "Legendary"
        case 8: return "Ultimate Master"
        default: return "Level \(newTier + 1)"
        }
    }

    private var displayLevel: Int {
        newTier + 1
    }

    private var tierColor: Color {
        let intensity = Double(newTier) / 8.0
        if intensity < 0.4 {
            return Color("ElectricBlue")
        } else if intensity < 0.7 {
            return Color("NeonPink")
        } else {
            return Color("HotMagenta")
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Particle burst
            ForEach(0..<40, id: \.self) { index in
                ParticleBurst(index: index, isAnimating: isAnimating, color: tierColor)
            }

            VStack(spacing: 24) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [tierColor, tierColor.opacity(0.3)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: tierColor, radius: 30)
                        .scaleEffect(pulseScale)

                    VStack(spacing: 4) {
                        Text("LEVEL")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("\(displayLevel)")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .rotationEffect(.degrees(rotationDegrees))
                }
                .scaleEffect(isAnimating ? 1.0 : 0.3)
                .opacity(isAnimating ? 1 : 0)

                // Level name
                Text(tierName.uppercased())
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [tierColor, Color("NeonYellow")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: tierColor, radius: 20)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1 : 0)

                // Stars
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color("NeonYellow"))
                            .shadow(color: Color("NeonYellow"), radius: 10)
                            .scaleEffect(isAnimating ? 1.0 : 0.3)
                            .opacity(isAnimating ? 1 : 0)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.6)
                                .delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
            }
        }
        .onAppear {
            // Play level up sound
            audioManager.playSoundEffect(named: "node-unlock", withExtension: "wav", volume: 1.0)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                isAnimating = true
            }

            // Pulse animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }

            // Rotation animation
            withAnimation(.easeInOut(duration: 2.0)) {
                rotationDegrees = 360
            }

            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete()
            }
        }
    }
}

struct ParticleBurst: View {
    let index: Int
    let isAnimating: Bool
    let color: Color

    @State private var offset: CGSize = .zero
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        let size = CGFloat.random(in: 8...16)
        let angle = Double(index) * (360.0 / 40.0)
        let distance: CGFloat = 200

        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .shadow(color: color, radius: 6)
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let radians = angle * .pi / 180
                let endX = cos(radians) * distance
                let endY = sin(radians) * distance

                withAnimation(.easeOut(duration: 1.0)) {
                    offset = CGSize(width: endX, height: endY)
                    opacity = 0
                    scale = 0.5
                }
            }
    }
}

#Preview {
    LevelUpOverlay(newTier: 3) {
        print("Level up complete")
    }
    .environment(AudioManager.shared)
}
