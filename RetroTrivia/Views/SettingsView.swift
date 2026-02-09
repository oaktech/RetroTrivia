import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var gameState
    @Environment(QuestionManager.self) private var questionManager
    @Environment(AudioManager.self) private var audioManager

    // Developer mode
    @State private var devTapCount = 0
    @State private var showDevTools = false
    @State private var uploader = CloudKitUploader()

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

                    // Category Display (locked/informational) - tap 5x for dev tools
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
                    .onTapGesture {
                        devTapCount += 1
                        if devTapCount >= 5 {
                            showDevTools = true
                            devTapCount = 0
                        }
                    }

                    // Developer Tools (hidden by default)
                    if showDevTools {
                        Divider()
                            .background(Color("NeonYellow").opacity(0.5))
                            .padding(.horizontal)
                            .padding(.top, 10)

                        VStack(spacing: 15) {
                            Text("Developer Tools")
                                .retroBody()
                                .foregroundStyle(Color("NeonYellow"))

                            Text(uploader.progress)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            HStack(spacing: 12) {
                                Button(action: {
                                    Task { await uploader.uploadAllQuestions() }
                                }) {
                                    Text("Upload")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color("NeonPink").opacity(0.3))
                                        .foregroundStyle(Color("NeonPink"))
                                        .cornerRadius(8)
                                }
                                .disabled(uploader.isUploading)

                                Button(action: {
                                    Task { await uploader.deleteAllQuestions() }
                                }) {
                                    Text("Delete All")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.red.opacity(0.3))
                                        .foregroundStyle(.red)
                                        .cornerRadius(8)
                                }
                                .disabled(uploader.isUploading)

                                Button(action: {
                                    questionManager.clearCache()
                                }) {
                                    Text("Clear Cache")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.3))
                                        .foregroundStyle(.orange)
                                        .cornerRadius(8)
                                }
                            }

                            Button(action: { showDevTools = false }) {
                                Text("Hide Dev Tools")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding(.top, 5)
                    }
                }
                .padding(.top, 10)

                Spacer()

                // Info text
                VStack(spacing: 8) {
                    Text("80s Music Trivia")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

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
