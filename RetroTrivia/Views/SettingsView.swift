import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
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
                        Text("Questions from Open Trivia Database")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    } else {
                        Text("Using bundled 80s music questions")
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
        .environment(QuestionManager())
        .environment(AudioManager.shared)
}
