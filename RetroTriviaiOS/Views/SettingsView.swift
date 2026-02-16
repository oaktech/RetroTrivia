import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GameState.self) private var gameState
    @Environment(QuestionManager.self) private var questionManager
    @Environment(AudioManager.self) private var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    // Developer mode
    @State private var devTapCount = 0
    @State private var showDevTools = false
    @State private var showCredits = false
    @State private var uploader = CloudKitUploader()

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        ZStack {
            // Retro background
            RetroGradientBackground()

            if metrics.isIPad {
                StageSpotlightOverlay()
            }

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
                    // Category Display (locked/informational) - tap 5x for dev tools
                    HStack {
                        Text("Category")
                            .font(.system(size: metrics.isIPad ? 16 : 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        HStack(spacing: 6) {
                            Text("80s Trivia")
                                .font(.system(size: metrics.isIPad ? 15 : 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color("ElectricBlue"))

                            Image(systemName: "lock.fill")
                                .font(.system(size: metrics.isIPad ? 14 : 12))
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

                            // Bundle-only mode toggle
                        #if DEBUG
                        Toggle(isOn: Binding(
                            get: { questionManager.forceBundleMode },
                            set: { questionManager.forceBundleMode = $0 }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Bundle Questions Only")
                                    .font(.caption)
                                    .foregroundStyle(Color("NeonYellow"))
                                Text("Skips CloudKit — uses 200 bundled questions")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .tint(Color("NeonYellow"))
                        .padding(.horizontal)
                        #endif

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

                // Credits button
                Button {
                    showCredits = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "music.note")
                            .font(.system(size: metrics.isIPad ? 15 : 12))
                        Text("Credits & Licenses")
                            .font(.system(size: metrics.isIPad ? 15 : 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(Color("ElectricBlue").opacity(0.8))
                }

                // Info text
                VStack(spacing: 8) {
                    Text("80s Trivia Game")
                        .font(.system(size: metrics.isIPad ? 14 : 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("Changes apply on next game")
                        .font(.system(size: metrics.isIPad ? 12 : 10, design: .rounded))
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
            .frame(maxWidth: metrics.settingsMaxWidth)
        }
        .sheet(isPresented: $showCredits) {
            CreditsView()
        }
    }
}

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            RetroGradientBackground()

            ScrollView {
                VStack(spacing: 24) {
                    Text("Credits")
                        .retroHeading()
                        .foregroundStyle(Color("NeonPink"))
                        .padding(.top, 40)

                    Divider()
                        .background(Color("NeonPink").opacity(0.3))
                        .padding(.horizontal)

                    // Music Credits
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Music")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("ElectricBlue"))

                        MusicCreditRow(
                            title: "Electric Lullaby",
                            artist: "Electronic Senses",
                            usage: "Menu Music",
                            url: "https://soundcloud.com/electronicsenses",
                            license: "CC BY-SA 3.0",
                            promotedBy: "free-stock-music.com"
                        )

                        MusicCreditRow(
                            title: "Retro",
                            artist: "jiglr",
                            usage: "Gameplay Music",
                            url: "https://soundcloud.com/jiglrmusic",
                            license: "CC BY 3.0",
                            promotedBy: "free-stock-music.com"
                        )
                    }
                    .padding(.horizontal, 24)

                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.horizontal, 24)

                    // Sound Effects
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sound Effects")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("ElectricBlue"))

                        CreditLine(label: "Correct answer sound", credit: "chrisiex1 via Pixabay")
                        CreditLine(label: "Wrong answer sound", credit: "freesound_community via Pixabay")
                        CreditLine(label: "Button click sound", credit: "CreatorsHome via Pixabay")
                        CreditLine(label: "Music toggle sound", credit: "Homemade_SFX via Pixabay")
                        CreditLine(label: "Wrong buzzer sound", credit: "freesound_community via Pixabay")
                        CreditLine(label: "Back button sound", credit: "Emiliano Dleon via Pixabay")
                        CreditLine(label: "Node unlock sound", credit: "Mixkit")
                    }
                    .padding(.horizontal, 24)

                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.horizontal, 24)

                    // License info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Licenses")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(Color("ElectricBlue"))

                        Text("CC BY-SA 3.0 — Creative Commons Attribution-ShareAlike 3.0 Unported")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("CC BY 3.0 — Creative Commons Attribution 3.0 Unported")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))

                        Text("Sound effects from Pixabay and Mixkit are used under their respective free licenses, which allow commercial use without attribution.")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 30)

                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color("NeonPink"))
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color("NeonPink").opacity(0.15))
                            .cornerRadius(12)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
    }
}

struct MusicCreditRow: View {
    let title: String
    let artist: String
    let usage: String
    let url: String
    let license: String
    var promotedBy: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\"\(title)\"")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Spacer()

                Text(usage)
                    .font(.caption2)
                    .foregroundStyle(Color("NeonYellow").opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color("NeonYellow").opacity(0.1))
                    .cornerRadius(4)
            }

            Text("by \(artist)")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            if let urlObj = URL(string: url) {
                Link(url, destination: urlObj)
                    .font(.caption2)
                    .foregroundStyle(Color("ElectricBlue").opacity(0.7))
            }

            HStack(spacing: 8) {
                Text("License: \(license)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))

                if let promoted = promotedBy {
                    Text("Promoted by \(promoted)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.05))
        .cornerRadius(8)
    }
}

struct CreditLine: View {
    let label: String
    let credit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(credit)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.4))
        }
    }
}

#Preview {
    SettingsView()
        .environment(GameState())
        .environment(QuestionManager())
        .environment(AudioManager.shared)
}
