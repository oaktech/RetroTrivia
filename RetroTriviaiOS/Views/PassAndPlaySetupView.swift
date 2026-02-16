//
//  PassAndPlaySetupView.swift
//  RetroTrivia
//

import SwiftUI

struct PassAndPlaySetupView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let onStart: (PassAndPlaySession) -> Void
    let onCancel: () -> Void

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    @State private var playerCount = 2
    @State private var playerNames: [String] = ["", ""]
    @State private var selectedDifficulty: Difficulty = .any
    @State private var selectedRoundLimit: Int = 5  // 5, 10, 15 -> index represents fixed, -1 for raceTo25

    private let playerColors: [Color] = [Color("NeonPink"), Color("ElectricBlue"), Color("NeonYellow"), Color("HotMagenta")]

    // MARK: - Adaptive font sizes

    private var sectionLabelFont: CGFloat { metrics.isIPad ? 17 : 14 }
    private var countButtonFont: CGFloat { metrics.isIPad ? 22 : 18 }
    private var nameFieldFont: CGFloat { metrics.isIPad ? 16 : 14 }
    private var difficultyButtonFont: CGFloat { metrics.isIPad ? 15 : 12 }
    private var gameModeFont: CGFloat { metrics.isIPad ? 16 : 14 }
    private var gameModeCheckSize: CGFloat { metrics.isIPad ? 20 : 16 }
    private var playerDotSize: CGFloat { metrics.isIPad ? 28 : 20 }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            if metrics.isIPad {
                StageSpotlightOverlay()
            }

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("PASS & PLAY")
                        .font(.system(size: metrics.isIPad ? 40 : 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("NeonPink"), Color("ElectricBlue")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color("NeonPink").opacity(0.8), radius: 10)

                    Text("Multiplayer Trivia")
                        .font(.system(size: metrics.isIPad ? 18 : 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                }
                .padding(.top, 20)

                ScrollView {
                    if metrics.isIPad {
                        // iPad: two-column layout
                        HStack(alignment: .top, spacing: 20) {
                            // Left column: Who's Playing
                            playersSection
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("RetroPurple").opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("NeonPink").opacity(0.4), lineWidth: 1.5)
                                )

                            // Right column: Game Settings
                            settingsSection
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("RetroPurple").opacity(0.4))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color("ElectricBlue").opacity(0.4), lineWidth: 1.5)
                                )
                        }
                        .padding(.horizontal, 20)
                    } else {
                        // iPhone: single-column layout
                        VStack(spacing: 24) {
                            playerCountSelector
                            playerNameInputs
                            difficultySelector
                            roundLimitSelector
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Start / Cancel buttons
                HStack(spacing: 12) {
                    RetroButton("Cancel", variant: .secondary) {
                        audioManager.playSoundEffect(named: "button-tap")
                        onCancel()
                    }
                    .frame(maxWidth: .infinity)

                    RetroButton("Start Game", variant: .primary) {
                        audioManager.playSoundEffect(named: "button-tap")
                        startGame()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(maxWidth: metrics.passAndPlaySetupMaxWidth)
        }
    }

    // MARK: - iPad Section Cards

    private var playersSection: some View {
        VStack(spacing: 20) {
            Text("WHO'S PLAYING")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color("NeonPink").opacity(0.9))
                .tracking(2)

            playerCountSelector
            playerNameInputs
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 20) {
            Text("GAME SETTINGS")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(Color("ElectricBlue").opacity(0.9))
                .tracking(2)

            difficultySelector
            roundLimitSelector
        }
    }

    // MARK: - Shared Section Components

    private var playerCountSelector: some View {
        VStack(spacing: 12) {
            Text("Number of Players")
                .font(.system(size: sectionLabelFont, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 12) {
                ForEach([2, 3, 4], id: \.self) { count in
                    Button(action: {
                        audioManager.playSoundEffect(named: "button-tap")
                        playerCount = count
                        updatePlayerNames()
                    }) {
                        Text("\(count)")
                            .font(.system(size: countButtonFont, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, metrics.isIPad ? 14 : 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(playerCount == count ? Color("NeonPink").opacity(0.8) : Color("RetroPurple").opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        playerCount == count ? Color("NeonPink") : Color.white.opacity(0.2),
                                        lineWidth: playerCount == count ? 2 : 1
                                    )
                            )
                            .foregroundStyle(playerCount == count ? .white : .white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var playerNameInputs: some View {
        VStack(spacing: 12) {
            Text("Player Names")
                .font(.system(size: sectionLabelFont, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            ForEach(0..<playerCount, id: \.self) { index in
                HStack(spacing: 12) {
                    // Color dot
                    Circle()
                        .fill(playerColors[index % playerColors.count])
                        .frame(width: playerDotSize, height: playerDotSize)

                    // Name input with placeholder
                    ZStack(alignment: .leading) {
                        // Placeholder text
                        if playerNames[index].isEmpty {
                            Text("Player \(index + 1)")
                                .font(.system(size: nameFieldFont, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.horizontal, 12)
                                .padding(.vertical, metrics.isIPad ? 12 : 10)
                        }

                        // Actual input
                        TextField("", text: $playerNames[index])
                            .font(.system(size: nameFieldFont, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, metrics.isIPad ? 12 : 10)
                            .foregroundStyle(.white)
                    }
                    .background(Color("RetroPurple").opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(playerColors[index % playerColors.count].opacity(0.6), lineWidth: 1.5)
                    )
                }
            }
        }
    }

    private var difficultySelector: some View {
        VStack(spacing: 12) {
            Text("Difficulty")
                .font(.system(size: sectionLabelFont, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 8) {
                ForEach([Difficulty.any, Difficulty.easy, Difficulty.medium, Difficulty.hard], id: \.self) { difficulty in
                    Button(action: {
                        audioManager.playSoundEffect(named: "button-tap")
                        selectedDifficulty = difficulty
                    }) {
                        Text(difficulty.displayName)
                            .font(.system(size: difficultyButtonFont, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, metrics.isIPad ? 10 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedDifficulty == difficulty ? Color("ElectricBlue").opacity(0.8) : Color("RetroPurple").opacity(0.6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        selectedDifficulty == difficulty ? Color("ElectricBlue") : Color.white.opacity(0.2),
                                        lineWidth: selectedDifficulty == difficulty ? 2 : 1
                                    )
                            )
                            .foregroundStyle(selectedDifficulty == difficulty ? .white : .white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var roundLimitSelector: some View {
        VStack(spacing: 12) {
            Text("Game Mode")
                .font(.system(size: sectionLabelFont, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 8) {
                ForEach([(5, "5 Questions Each"), (10, "10 Questions Each"), (15, "15 Questions Each"), (-1, "Race to Node 25")], id: \.0) { count, label in
                    Button(action: {
                        audioManager.playSoundEffect(named: "button-tap")
                        selectedRoundLimit = count
                    }) {
                        HStack {
                            Text(label)
                                .font(.system(size: gameModeFont, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)

                            Spacer()

                            if selectedRoundLimit == count {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: gameModeCheckSize))
                                    .foregroundStyle(Color("NeonYellow"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, metrics.isIPad ? 12 : 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedRoundLimit == count ? Color("HotMagenta").opacity(0.3) : Color("RetroPurple").opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    selectedRoundLimit == count ? Color("HotMagenta") : Color.white.opacity(0.2),
                                    lineWidth: selectedRoundLimit == count ? 2 : 1
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Logic

    private func updatePlayerNames() {
        if playerNames.count < playerCount {
            for i in playerNames.count..<playerCount {
                playerNames.append("Player \(i + 1)")
            }
        } else if playerNames.count > playerCount {
            playerNames = Array(playerNames.prefix(playerCount))
        }
    }

    private func startGame() {
        let roundLimit: RoundLimit = selectedRoundLimit == -1 ? .raceTo25 : .fixed(selectedRoundLimit)
        let session = PassAndPlaySession(
            playerNames: playerNames.prefix(playerCount).map { $0.isEmpty ? "Player" : $0 },
            roundLimit: roundLimit,
            difficulty: selectedDifficulty
        )
        onStart(session)
    }
}

#Preview {
    PassAndPlaySetupView(onStart: { _ in }, onCancel: {})
        .environment(AudioManager.shared)
}
