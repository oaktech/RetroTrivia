//
//  PodiumBar.swift
//  RetroTrivia
//

import SwiftUI

/// Horizontal stats bar styled like game show contestant podiums.
struct PodiumBar: View {
    let items: [PodiumItem]

    var body: some View {
        HStack(spacing: 12) {
            ForEach(items) { item in
                PodiumCard(item: item)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct PodiumItem: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
    let label: String
    var color: Color = Color("ElectricBlue")
    var isHighlighted: Bool = false
}

private struct PodiumCard: View {
    let item: PodiumItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(item.color)
                .shadow(color: item.isHighlighted ? item.color.opacity(0.6) : .clear, radius: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.value)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Text(item.label)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(item.isHighlighted ? item.color.opacity(0.06) : Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(item.color.opacity(item.isHighlighted ? 0.5 : 0.2), lineWidth: 1.5)
        )
        .shadow(color: item.isHighlighted ? item.color.opacity(0.25) : .clear, radius: 10)
    }
}

// MARK: - Player Podium Card (for Pass & Play)

struct PlayerPodiumCard: View {
    let name: String
    let color: Color
    let position: Int
    let score: String
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Text(name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                VStack(spacing: 1) {
                    Text("\(position)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(color)
                    Text("Pos")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                VStack(spacing: 1) {
                    Text(score)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Score")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(isCurrent ? 0.15 : 0.05))
                .stroke(color.opacity(isCurrent ? 0.6 : 0.2), lineWidth: isCurrent ? 2 : 1)
        )
        .shadow(color: isCurrent ? color.opacity(0.4) : .clear, radius: isCurrent ? 8 : 0)
    }
}

#Preview {
    ZStack {
        Color("RetroPurple").ignoresSafeArea()
        VStack(spacing: 20) {
            PodiumBar(items: [
                PodiumItem(icon: "flame.fill", value: "5", label: "Streak", color: Color("NeonPink"), isHighlighted: true),
                PodiumItem(icon: "target", value: "80%", label: "Accuracy", color: Color("ElectricBlue")),
                PodiumItem(icon: "heart.fill", value: "3", label: "Lives", color: Color("NeonPink")),
                PodiumItem(icon: "medal.fill", value: "x3", label: "Badges", color: Color("NeonYellow"))
            ])
        }
    }
}
