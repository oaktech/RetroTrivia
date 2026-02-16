//
//  BadgeGalleryView.swift
//  RetroTrivia
//

import SwiftUI

struct BadgeGalleryView: View {
    @Environment(BadgeManager.self) private var badgeManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onClose: () -> Void

    @State private var appeared = false

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    private var columns: [GridItem] {
        let count = metrics.isIPad ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 10) {
                    Text("BADGES")
                        .retroHeading()

                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color("NeonYellow"))
                        Text("\(badgeManager.unlockedIDs.count) / \(Badge.all.count) unlocked")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color("NeonYellow").opacity(0.06))
                            .stroke(Color("NeonYellow").opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.top, 24)
                .padding(.bottom, 20)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(Badge.all.enumerated()), id: \.element.id) { idx, badge in
                            BadgeCardView(
                                badge: badge,
                                isUnlocked: badgeManager.isUnlocked(badge.id),
                                isIPad: metrics.isIPad
                            )
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.6)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(idx) * 0.04),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, metrics.isIPad ? 32 : 20)
                    .padding(.bottom, 48)
                }

                RetroButton("Close", variant: .primary) {
                    onClose()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Flippable Badge Card

private struct BadgeCardView: View {
    let badge: Badge
    let isUnlocked: Bool
    let isIPad: Bool

    @Environment(AudioManager.self) private var audioManager
    @State private var isFlipped = false
    @State private var shimmer = false
    @State private var snapBackTask: Task<Void, Never>?

    private var iconSize: CGFloat { isIPad ? 48 : 40 }
    private var glowSize: CGFloat { isIPad ? 76 : 66 }
    private var titleSize: CGFloat { isIPad ? 18 : 16 }
    private var descSize: CGFloat { isIPad ? 15 : 13 }
    private var vPad: CGFloat { isIPad ? 24 : 22 }

    var body: some View {
        ZStack {
            // Front face
            cardFront
                .opacity(isFlipped ? 0 : 1)

            // Back face (pre-rotated so it reads correctly when container hits 180°)
            cardBack
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.4
        )
        .onTapGesture {
            audioManager.playSoundEffect(named: "card-flip")
            snapBackTask?.cancel()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
            if isFlipped {
                snapBackTask = Task {
                    try? await Task.sleep(for: .seconds(3))
                    guard !Task.isCancelled else { return }
                    audioManager.playSoundEffect(named: "card-flip")
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isFlipped = false
                    }
                }
            }
        }
        .onAppear { if isUnlocked { shimmer = true } }
    }

    // MARK: - Front Face

    @ViewBuilder
    private var cardFront: some View {
        VStack(spacing: 10) {
            ZStack {
                if isUnlocked {
                    Circle()
                        .fill(Color(badge.iconColor).opacity(shimmer ? 0.22 : 0.06))
                        .frame(width: glowSize, height: glowSize)
                        .animation(
                            .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                            value: shimmer
                        )
                }

                Image(systemName: isUnlocked ? badge.iconName : "lock.fill")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(
                        isUnlocked ? Color(badge.iconColor) : .white.opacity(0.15)
                    )
                    .shadow(
                        color: isUnlocked ? Color(badge.iconColor).opacity(0.6) : .clear,
                        radius: isUnlocked ? 10 : 0
                    )
            }
            .frame(height: glowSize)

            VStack(spacing: 4) {
                Text(badge.title)
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(isUnlocked ? .white : .white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(isUnlocked ? badge.description : "Tap to reveal hint")
                    .font(.system(size: descSize, weight: .medium, design: .rounded))
                    .foregroundStyle(isUnlocked ? .white.opacity(0.75) : .white.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, vPad)
        .padding(.horizontal, 12)
        .background(cardBackground)
        .shadow(color: isUnlocked ? Color(badge.iconColor).opacity(0.15) : .clear, radius: 12)
    }

    // MARK: - Back Face

    @ViewBuilder
    private var cardBack: some View {
        VStack(spacing: 12) {
            if isUnlocked {
                // Unlocked back: celebration + details
                Text("★ EARNED ★")
                    .font(.system(size: isIPad ? 15 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(Color(badge.iconColor))
                    .tracking(2)

                Image(systemName: badge.iconName)
                    .font(.system(size: isIPad ? 32 : 26, weight: .bold))
                    .foregroundStyle(Color(badge.iconColor).opacity(0.5))

                Text(badge.title)
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(badge.description)
                    .font(.system(size: descSize, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                // Locked back: how to earn
                Text("HOW TO EARN")
                    .font(.system(size: isIPad ? 15 : 13, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .tracking(2)

                Image(systemName: "lock.open.fill")
                    .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                    .foregroundStyle(Color("ElectricBlue").opacity(0.4))

                Text(badge.description)
                    .font(.system(size: descSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Text("Keep playing!")
                    .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("ElectricBlue").opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, vPad)
        .padding(.horizontal, 12)
        .background(cardBackBackground)
    }

    // MARK: - Card Backgrounds

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isUnlocked
                ? Color(badge.iconColor).opacity(0.08)
                : Color.white.opacity(0.03)
            )
            .stroke(
                isUnlocked
                ? Color(badge.iconColor).opacity(0.35)
                : Color.white.opacity(0.08),
                lineWidth: isUnlocked ? 1.5 : 1
            )
    }

    private var cardBackBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                isUnlocked
                ? Color(badge.iconColor).opacity(0.12)
                : Color.white.opacity(0.05)
            )
            .stroke(
                isUnlocked
                ? Color(badge.iconColor).opacity(0.45)
                : Color.white.opacity(0.12),
                lineWidth: isUnlocked ? 1.5 : 1
            )
    }
}

#Preview {
    BadgeGalleryView(onClose: {})
        .environment(BadgeManager.shared)
        .environment(AudioManager.shared)
}
