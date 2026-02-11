//
//  MapNodeView.swift
//  RetroTrivia
//

import SwiftUI

struct MapNodeView: View {
    let levelIndex: Int
    let isCurrentPosition: Bool
    let currentPosition: Int
    var isAnimatingTarget: Bool = false
    var playerDots: [Color] = []  // NEW: Pass & Play player dots

    @State private var pulseScale: CGFloat = 1.0
    @State private var animationRotation: Double = 0
    @State private var targetPulseScale: CGFloat = 1.0

    private var nodeState: NodeState {
        if levelIndex == currentPosition {
            return .current
        } else if levelIndex < currentPosition {
            return .completed
        } else {
            return .locked
        }
    }

    // MARK: - Progressive Intensity

    private var intensityMultiplier: Double {
        // Intensity increases every 3 levels (creates distinct tiers)
        let tier = Double(levelIndex / 3)
        let maxTier = Double(25 / 3) // 8 tiers total (0-8)
        return tier / maxTier
    }

    private var shouldPulse: Bool {
        let isNearPlayer = abs(levelIndex - currentPosition) <= 10
        return nodeState == .completed && levelIndex >= 20 && isNearPlayer
    }

    private var isLegendaryTier: Bool {
        levelIndex >= 23 && nodeState == .completed
    }

    var body: some View {
        ZStack {
            // Pass & Play: Show player dots if provided
            if !playerDots.isEmpty {
                HStack(spacing: playerDots.count > 1 ? -8 : 0) {
                    ForEach(playerDots.indices, id: \.self) { index in
                        Circle()
                            .fill(playerDots[index])
                            .frame(width: 24, height: 24)
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .shadow(color: playerDots[index].opacity(0.6), radius: 8)
                    }
                }
            } else {
                // Standard single-player mode
                ZStack {
                    // Node circle
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: nodeSize, height: nodeSize)
                        .overlay(borderOverlay)
                        .compositingGroup()
                        .shadow(color: shadowColor, radius: shadowRadius(for: levelIndex, state: nodeState))
                        .shadow(
                            color: isLegendaryTier ? Color("NeonYellow").opacity(0.4) : .clear,
                            radius: isLegendaryTier ? shadowRadius(for: levelIndex, state: nodeState) * 1.5 : 0
                        )

                    // Icon or number
                    if nodeState == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color("NeonPink"))
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(iconColor)
                    }
                }
            }
        }
        .scaleEffect(scaleEffect * targetPulseScale)
        .animation(.spring(response: 0.3), value: currentPosition)
        .onChange(of: isAnimatingTarget) { oldValue, newValue in
            // Pulsate when this node is the target of movement
            if newValue {
                withAnimation(.easeInOut(duration: 0.3).repeatCount(3, autoreverses: true)) {
                    targetPulseScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    self.targetPulseScale = 1.0
                }
            }
        }
        .onChange(of: currentPosition) { oldValue, newValue in
            // Update pulse animation when state changes
            if shouldPulse && pulseScale == 1.0 {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.12
                }
            } else if !shouldPulse && pulseScale != 1.0 {
                pulseScale = 1.0
            }

            // Update legendary animation when state changes
            if isLegendaryTier && animationRotation == 0 {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    animationRotation = 360
                }
            }
        }
        .onAppear {
            if shouldPulse {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    pulseScale = 1.12
                }
            }
            if isLegendaryTier {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    animationRotation = 360
                }
            }
        }
    }

    private var nodeSize: CGFloat {
        let baseSize: CGFloat = 50
        let maxGrowth: CGFloat = 50
        let size = baseSize + (maxGrowth * intensityMultiplier)
        return isCurrentPosition ? size * 1.2 : size
    }

    private var borderWidth: CGFloat {
        let baseBorder: CGFloat = 1.5
        let maxBorder: CGFloat = 8
        let width = baseBorder + (maxBorder - baseBorder) * intensityMultiplier
        return isCurrentPosition ? width * 1.4 : width
    }

    private var backgroundColor: Color {
        switch nodeState {
        case .current:
            return Color("RetroPurple").opacity(0.9)
        case .completed:
            return Color("RetroPurple").opacity(0.6)
        case .locked:
            return Color("RetroPurple").opacity(0.3)
        }
    }

    private func calculateBorderColor(for level: Int, state: NodeState) -> Color {
        switch state {
        case .current:
            return Color("NeonPink") // Always NeonPink for consistency

        case .completed:
            // Tier-based intensity (increases every 3 levels)
            let tier = Double(level / 3)
            let maxTier = Double(25 / 3)
            let intensity = tier / maxTier

            // First transition at tier 2 (0.25), then every 2 tiers (0.5, 0.75)
            if intensity < 0.25 { // Tiers 0-1 (levels 0-5)
                return Color("ElectricBlue")
            } else if intensity < 0.5 { // Tiers 2-3 (levels 6-11)
                // Blend ElectricBlue → NeonPink
                let blendFactor = (intensity - 0.25) / 0.25
                return Color("ElectricBlue").interpolate(to: Color("NeonPink"), amount: blendFactor)
            } else if intensity < 0.75 { // Tiers 4-5 (levels 12-20)
                // Blend NeonPink → HotMagenta
                let blendFactor = (intensity - 0.5) / 0.25
                return Color("NeonPink").interpolate(to: Color("HotMagenta"), amount: blendFactor)
            } else { // Tiers 6-8 (levels 21-25)
                return Color("HotMagenta")
            }

        case .locked:
            return Color.white.opacity(0.3)
        }
    }

    private var borderColor: Color {
        calculateBorderColor(for: levelIndex, state: nodeState)
    }

    private var iconColor: Color {
        switch nodeState {
        case .current:
            return Color("NeonYellow")
        case .completed:
            return Color("ElectricBlue")
        case .locked:
            return Color.white.opacity(0.4)
        }
    }

    private func calculateShadowColor(for level: Int, state: NodeState) -> Color {
        switch state {
        case .current:
            return Color("NeonPink").opacity(0.9)
        case .completed:
            let baseColor = calculateBorderColor(for: level, state: state)
            // Increase opacity with intensity for stronger glow at higher levels
            let tier = Double(level / 3)
            let maxTier = Double(25 / 3)
            let intensity = tier / maxTier
            let opacity = 0.4 + (0.4 * intensity) // 0.4 to 0.8
            return baseColor.opacity(opacity)
        case .locked:
            return Color.clear
        }
    }

    private var shadowColor: Color {
        calculateShadowColor(for: levelIndex, state: nodeState)
    }

    private func shadowRadius(for level: Int, state: NodeState) -> CGFloat {
        // Tier-based intensity (increases every 3 levels)
        let tier = Double(level / 3)
        let maxTier = Double(25 / 3)
        let intensity = tier / maxTier

        switch state {
        case .current:
            return 15 + (60 - 15) * intensity
        case .completed:
            return 3 + (50 - 3) * intensity
        case .locked:
            return 0
        }
    }

    private var scaleEffect: CGFloat {
        if isCurrentPosition {
            return 1.25
        } else if shouldPulse {
            return pulseScale
        }
        return 1.0
    }

    private var borderOverlay: some View {
        Group {
            if isLegendaryTier {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color("HotMagenta"),
                                Color("NeonYellow"),
                                Color("NeonPink"),
                                Color("HotMagenta")
                            ],
                            center: .center,
                            startAngle: .degrees(animationRotation),
                            endAngle: .degrees(animationRotation + 360)
                        ),
                        lineWidth: borderWidth
                    )
            } else {
                Circle()
                    .stroke(borderColor, lineWidth: borderWidth)
            }
        }
    }
}

enum NodeState {
    case current
    case completed
    case locked
}

#Preview {
    ZStack {
        Color("RetroPurple")
            .ignoresSafeArea()

        VStack(spacing: 40) {
            MapNodeView(levelIndex: 0, isCurrentPosition: false, currentPosition: 5)
            MapNodeView(levelIndex: 5, isCurrentPosition: true, currentPosition: 5)
            MapNodeView(levelIndex: 10, isCurrentPosition: false, currentPosition: 5)
        }
    }
}

// MARK: - Color Extension for Interpolation

extension Color {
    func interpolate(to target: Color, amount: Double) -> Color {
        let amount = max(0, min(1, amount)) // Clamp between 0 and 1

        // Convert to UIColor for component access
        #if canImport(UIKit)
        let fromColor = UIColor(self)
        let toColor = UIColor(target)

        var fromRed: CGFloat = 0
        var fromGreen: CGFloat = 0
        var fromBlue: CGFloat = 0
        var fromAlpha: CGFloat = 0

        var toRed: CGFloat = 0
        var toGreen: CGFloat = 0
        var toBlue: CGFloat = 0
        var toAlpha: CGFloat = 0

        fromColor.getRed(&fromRed, green: &fromGreen, blue: &fromBlue, alpha: &fromAlpha)
        toColor.getRed(&toRed, green: &toGreen, blue: &toBlue, alpha: &toAlpha)

        let red = fromRed + (toRed - fromRed) * amount
        let green = fromGreen + (toGreen - fromGreen) * amount
        let blue = fromBlue + (toBlue - fromBlue) * amount
        let alpha = fromAlpha + (toAlpha - fromAlpha) * amount

        return Color(red: red, green: green, blue: blue, opacity: alpha)
        #else
        return self
        #endif
    }
}
