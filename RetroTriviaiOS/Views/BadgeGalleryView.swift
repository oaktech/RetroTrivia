//
//  BadgeGalleryView.swift
//  RetroTrivia
//

import SwiftUI

struct BadgeGalleryView: View {
    @Environment(BadgeManager.self) private var badgeManager
    let onClose: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 6) {
                    Text("BADGES")
                        .retroHeading()

                    Text("\(badgeManager.unlockedIDs.count) / \(Badge.all.count) unlocked")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Badge.all) { badge in
                            BadgeCardView(
                                badge: badge,
                                isUnlocked: badgeManager.isUnlocked(badge.id)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }

                RetroButton("Close", variant: .primary) {
                    onClose()
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Badge Card

private struct BadgeCardView: View {
    let badge: Badge
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: badge.iconName)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(isUnlocked ? Color(badge.iconColor) : Color.white.opacity(0.25))
                .shadow(color: isUnlocked ? Color(badge.iconColor).opacity(0.6) : .clear, radius: 8)
                .saturation(isUnlocked ? 1 : 0)

            Text(badge.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isUnlocked ? .white : .white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(isUnlocked ? badge.description : "???")
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(isUnlocked ? .white.opacity(0.6) : .white.opacity(0.25))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    isUnlocked
                    ? Color(badge.iconColor).opacity(0.08)
                    : Color.white.opacity(0.04)
                )
                .stroke(
                    isUnlocked
                    ? Color(badge.iconColor).opacity(0.35)
                    : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    BadgeGalleryView(onClose: {})
        .environment(BadgeManager.shared)
}
