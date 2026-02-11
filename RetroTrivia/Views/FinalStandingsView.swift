//
//  FinalStandingsView.swift
//  RetroTrivia
//

import SwiftUI

struct FinalStandingsView: View {
    @Environment(AudioManager.self) var audioManager
    let session: PassAndPlaySession
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    private var sortedPlayers: [PassAndPlayPlayer] {
        session.players.enumerated().sorted { item1, item2 in
            let (index1, player1) = item1
            let (index2, player2) = item2

            // Primary: sort by position (descending)
            if player1.position != player2.position {
                return player1.position > player2.position
            }
            // Tiebreaker 1: sort by correct answers (descending)
            if player1.correctAnswers != player2.correctAnswers {
                return player1.correctAnswers > player2.correctAnswers
            }
            // Final tiebreaker: maintain original order
            return index1 < index2
        }
        .map { $0.element }
    }

    var body: some View {
        ZStack {
            RetroGradientBackground()

            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                // Game Over title
                Text("GAME OVER")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("ElectricBlue")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: Color("NeonPink").opacity(0.8), radius: 12)

                Divider()
                    .frame(height: 2)
                    .background(
                        LinearGradient(
                            colors: [Color("NeonPink"), Color("ElectricBlue"), Color("HotMagenta")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.horizontal, 40)

                Spacer()

                // Podium
                VStack(spacing: 16) {
                    ForEach(sortedPlayers.indices, id: \.self) { index in
                        let player = sortedPlayers[index]
                        let medal = medalSymbol(for: index)
                        let isWinner = index == 0

                        HStack(spacing: 16) {
                            Text(medal)
                                .font(.system(size: 32))

                            Text(player.name)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            // Position badge
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(player.color.opacity(0.3))
                                    .stroke(player.color, lineWidth: 2)

                                HStack(spacing: 8) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 12))
                                    Text("\(player.position)")
                                        .font(.system(size: 18, weight: .black, design: .rounded))
                                }
                                .foregroundStyle(player.color)
                            }
                            .frame(width: 70)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("RetroPurple").opacity(isWinner ? 0.8 : 0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(player.color.opacity(isWinner ? 0.8 : 0.4), lineWidth: isWinner ? 2 : 1)
                                )
                        )
                        .shadow(color: isWinner ? player.color.opacity(0.6) : .clear, radius: isWinner ? 12 : 0)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // Stats
                VStack(spacing: 12) {
                    Divider()
                        .frame(height: 1)
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, 20)

                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("Total Questions")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(session.players.map(\.questionsAnswered).reduce(0, +))")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(Color("ElectricBlue"))
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Correct Answers")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(session.players.map(\.correctAnswers).reduce(0, +))")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(Color("NeonPink"))
                        }

                        Spacer()

                        VStack(spacing: 4) {
                            Text("Players")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                            Text("\(session.players.count)")
                                .font(.system(size: 24, weight: .black, design: .rounded))
                                .foregroundStyle(Color("NeonYellow"))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                Spacer()

                // Buttons
                HStack(spacing: 12) {
                    RetroButton("Play Again", variant: .primary) {
                        audioManager.playSoundEffect(named: "button-tap")
                        onPlayAgain()
                    }
                    .frame(maxWidth: .infinity)

                    RetroButton("Home", variant: .secondary) {
                        audioManager.playSoundEffect(named: "button-tap")
                        onHome()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
    }

    private func medalSymbol(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "🎵"
        }
    }
}

#Preview {
    let session = PassAndPlaySession(
        playerNames: ["Sarah", "Mike", "Alex"],
        roundLimit: .fixed(5),
        difficulty: .any
    )
    FinalStandingsView(
        session: session,
        onPlayAgain: {},
        onHome: {}
    )
    .environment(AudioManager.shared)
}
