//
//  GameShowAnswerTile.swift
//  RetroTrivia
//

import SwiftUI

/// iPad answer button with game-show letter label (A/B/C/D).
/// Features neon letter badge glow, press-scale animation, and smooth state transitions.
struct GameShowAnswerTile: View {
    let index: Int
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let hasAnswered: Bool
    let action: () -> Void

    private static let letters = ["A", "B", "C", "D"]
    private static let letterColors: [Color] = [
        Color("NeonPink"),
        Color("ElectricBlue"),
        Color("NeonYellow"),
        Color("HotMagenta")
    ]

    private var letterLabel: String {
        index < Self.letters.count ? Self.letters[index] : ""
    }

    private var letterColor: Color {
        index < Self.letterColors.count ? Self.letterColors[index] : Color("ElectricBlue")
    }

    private var tileBackground: Color {
        if !hasAnswered {
            return Color("RetroPurple").opacity(0.6)
        }
        if isCorrect {
            return .green.opacity(0.7)
        }
        if isSelected {
            return .red.opacity(0.7)
        }
        return Color("RetroPurple").opacity(0.3)
    }

    private var tileBorderColor: Color {
        if !hasAnswered {
            return letterColor.opacity(0.6)
        }
        if isCorrect {
            return .green
        }
        if isSelected {
            return .red
        }
        return Color("ElectricBlue").opacity(0.3)
    }

    private var tileShadowColor: Color {
        if !hasAnswered {
            return letterColor.opacity(0.2)
        }
        if isCorrect {
            return .green.opacity(0.4)
        }
        if isSelected {
            return .red.opacity(0.3)
        }
        return .clear
    }

    private var textColor: Color {
        if !hasAnswered { return .white }
        if isCorrect || isSelected { return .white }
        return .white.opacity(0.5)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Letter badge with neon glow
                Text(letterLabel)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(hasAnswered ? textColor : letterColor)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hasAnswered ? Color.clear : letterColor.opacity(0.12))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(hasAnswered ? Color.clear : letterColor.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: hasAnswered ? .clear : letterColor.opacity(0.4), radius: 8)

                // Answer text
                Text(text)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tileBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(tileBorderColor, lineWidth: 2)
            )
            .shadow(color: tileShadowColor, radius: 10)
            .animation(.easeInOut(duration: 0.3), value: hasAnswered)
        }
        .buttonStyle(AnswerTileButtonStyle())
        .disabled(hasAnswered)
    }
}

/// Custom button style that scales on press for game-show dramatic feedback.
private struct AnswerTileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .brightness(configuration.isPressed ? 0.05 : 0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color("RetroPurple").ignoresSafeArea()
        VStack(spacing: 16) {
            GameShowAnswerTile(index: 0, text: "Bad", isSelected: false, isCorrect: false, hasAnswered: false) {}
            GameShowAnswerTile(index: 1, text: "Thriller", isSelected: false, isCorrect: true, hasAnswered: true) {}
            GameShowAnswerTile(index: 2, text: "Off the Wall", isSelected: true, isCorrect: false, hasAnswered: true) {}
            GameShowAnswerTile(index: 3, text: "Dangerous", isSelected: false, isCorrect: false, hasAnswered: true) {}
        }
        .padding(40)
    }
}
