import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var gameState
    @Environment(QuestionManager.self) private var questionManager
    @Environment(AudioManager.self) private var audioManager

    var body: some View {
        ZStack {
            // Retro background
            RetroGradientBackground()

            VStack(spacing: 30) {
                // Header
                Text("Settings")
                    .retroHeading()
                    .foregroundStyle(Color("NeonPink"))
                    .padding(.top, 40)

                Divider()
                    .background(Color("NeonPink").opacity(0.3))
                    .padding(.horizontal)

                VStack(spacing: 25) {
                    // Online Questions Toggle
                    HStack {
                        Text("Online Questions")
                            .retroBody()
                            .foregroundStyle(.white)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { questionManager.filterConfig.enableOnlineQuestions },
                            set: { newValue in
                                audioManager.playSoundEffect(named: "button-tap")
                                questionManager.filterConfig.enableOnlineQuestions = newValue
                            }
                        ))
                        .tint(Color("NeonPink"))
                        .sensoryFeedback(.impact(weight: .light), trigger: questionManager.filterConfig.enableOnlineQuestions)
                    }
                    .padding(.horizontal, 30)

                    // Timer Toggle
                    HStack {
                        Text("Countdown Timer")
                            .retroBody()
                            .foregroundStyle(.white)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { gameState.gameSettings.timerEnabled },
                            set: { newValue in
                                audioManager.playSoundEffect(named: "button-tap")
                                gameState.gameSettings.timerEnabled = newValue
                            }
                        ))
                        .tint(Color("NeonPink"))
                        .sensoryFeedback(.impact(weight: .light), trigger: gameState.gameSettings.timerEnabled)
                    }
                    .padding(.horizontal, 30)

                    // Timer Duration Picker (only when timer is enabled)
                    if gameState.gameSettings.timerEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time per Question")
                                .retroBody()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 30)

                            Picker("Duration", selection: Binding(
                                get: { gameState.gameSettings.timerDuration },
                                set: { newValue in
                                    audioManager.playSoundEffect(named: "button-tap")
                                    gameState.gameSettings.timerDuration = newValue
                                }
                            )) {
                                Text("10s").tag(10)
                                Text("15s").tag(15)
                                Text("20s").tag(20)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 30)
                            .sensoryFeedback(.selection, trigger: gameState.gameSettings.timerDuration)
                        }
                    }

                    // Leaderboard Mode Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Leaderboard Mode")
                                .retroBody()
                                .foregroundStyle(.white)
                            Text("2-minute timed game")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { gameState.gameSettings.leaderboardMode },
                            set: { newValue in
                                audioManager.playSoundEffect(named: "button-tap")
                                gameState.gameSettings.leaderboardMode = newValue
                            }
                        ))
                        .tint(Color("NeonYellow"))
                        .sensoryFeedback(.impact(weight: .light), trigger: gameState.gameSettings.leaderboardMode)
                    }
                    .padding(.horizontal, 30)

                    // Lives Mode Toggle
                    HStack {
                        Text("Lives Mode")
                            .retroBody()
                            .foregroundStyle(.white)

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { gameState.gameSettings.livesEnabled },
                            set: { newValue in
                                audioManager.playSoundEffect(named: "button-tap")
                                gameState.gameSettings.livesEnabled = newValue
                            }
                        ))
                        .tint(Color("NeonPink"))
                        .sensoryFeedback(.impact(weight: .light), trigger: gameState.gameSettings.livesEnabled)
                    }
                    .padding(.horizontal, 30)

                    // Lives Count Picker (only when lives enabled)
                    if gameState.gameSettings.livesEnabled {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Starting Lives")
                                .retroBody()
                                .foregroundStyle(.white)
                                .padding(.horizontal, 30)

                            Picker("Starting Lives", selection: Binding(
                                get: { gameState.gameSettings.startingLives },
                                set: { newValue in
                                    audioManager.playSoundEffect(named: "button-tap")
                                    gameState.gameSettings.startingLives = newValue
                                }
                            )) {
                                Text("1").tag(1)
                                Text("2").tag(2)
                                Text("3").tag(3)
                                Text("5").tag(5)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 30)
                            .sensoryFeedback(.selection, trigger: gameState.gameSettings.startingLives)
                        }
                    }

                    // Difficulty Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Difficulty")
                            .retroBody()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 30)

                        Picker("Difficulty", selection: Binding(
                            get: { questionManager.filterConfig.difficulty },
                            set: { newValue in
                                audioManager.playSoundEffect(named: "button-tap")
                                questionManager.filterConfig.difficulty = newValue
                            }
                        )) {
                            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                                Text(difficulty.displayName)
                                    .tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 30)
                        .sensoryFeedback(.selection, trigger: questionManager.filterConfig.difficulty)
                    }

                    // Category Display (locked/informational)
                    HStack {
                        Text("Category")
                            .retroBody()
                            .foregroundStyle(.white)

                        Spacer()

                        HStack(spacing: 6) {
                            Text("Music")
                                .retroBody()
                                .foregroundStyle(Color("ElectricBlue"))

                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(Color("ElectricBlue").opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.top, 10)

                Spacer()

                // Info text
                VStack(spacing: 8) {
                    if questionManager.filterConfig.enableOnlineQuestions {
                        Text("Online questions include all music eras")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("(not limited to 80s)")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.5))
                    } else {
                        Text("Using curated 80s music questions")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Text("Changes apply on next game")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

                // Close Button
                RetroButton("Close", variant: .primary) {
                    audioManager.playSoundEffect(named: "button-tap")
                    dismiss()
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(GameState())
        .environment(QuestionManager())
        .environment(AudioManager.shared)
}
