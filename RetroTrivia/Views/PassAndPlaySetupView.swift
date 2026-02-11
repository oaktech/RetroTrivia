//
//  PassAndPlaySetupView.swift
//  RetroTrivia
//

import SwiftUI

struct PassAndPlaySetupView: View {
    @Environment(AudioManager.self) var audioManager
    let onStart: (PassAndPlaySession) -> Void
    let onCancel: () -> Void

    @State private var playerCount = 2
    @State private var playerNames: [String] = ["", ""]
    @State private var selectedDifficulty: Difficulty = .any
    @State private var selectedRoundLimit: Int = 5  // 5, 10, 15 -> index represents fixed, -1 for raceTo25

    private let playerColors: [Color] = [Color("NeonPink"), Color("ElectricBlue"), Color("NeonYellow"), Color("HotMagenta")]

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("PASS & PLAY")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("NeonPink"), Color("ElectricBlue")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color("NeonPink").opacity(0.8), radius: 10)

                    Text("Multiplayer Trivia")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                }
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 24) {
                        // Player count selector
                        VStack(spacing: 12) {
                            Text("Number of Players")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            HStack(spacing: 12) {
                                ForEach([2, 3, 4], id: \.self) { count in
                                    Button(action: {
                                        audioManager.playSoundEffect(named: "button-tap")
                                        playerCount = count
                                        updatePlayerNames()
                                    }) {
                                        Text("\(count)")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
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

                        // Player name inputs
                        VStack(spacing: 12) {
                            Text("Player Names")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            ForEach(0..<playerCount, id: \.self) { index in
                                HStack(spacing: 12) {
                                    // Color dot
                                    Circle()
                                        .fill(playerColors[index % playerColors.count])
                                        .frame(width: 20, height: 20)

                                    // Name input with placeholder
                                    ZStack(alignment: .leading) {
                                        // Placeholder text
                                        if playerNames[index].isEmpty {
                                            Text("Player \(index + 1)")
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.4))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                        }

                                        // Actual input
                                        TextField("", text: $playerNames[index])
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
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

                        // Difficulty selector
                        VStack(spacing: 12) {
                            Text("Difficulty")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            HStack(spacing: 8) {
                                ForEach([Difficulty.any, Difficulty.easy, Difficulty.medium, Difficulty.hard], id: \.self) { difficulty in
                                    Button(action: {
                                        audioManager.playSoundEffect(named: "button-tap")
                                        selectedDifficulty = difficulty
                                    }) {
                                        Text(difficulty.displayName)
                                            .font(.system(size: 12, weight: .bold, design: .rounded))
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 8)
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

                        // Round limit selector
                        VStack(spacing: 12) {
                            Text("Game Mode")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))

                            VStack(spacing: 8) {
                                ForEach([(5, "5 Questions Each"), (10, "10 Questions Each"), (15, "15 Questions Each"), (-1, "Race to Node 25")], id: \.0) { count, label in
                                    Button(action: {
                                        audioManager.playSoundEffect(named: "button-tap")
                                        selectedRoundLimit = count
                                    }) {
                                        HStack {
                                            Text(label)
                                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)

                                            Spacer()

                                            if selectedRoundLimit == count {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(Color("NeonYellow"))
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
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
                    .padding(.horizontal, 20)
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
        }
    }

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
