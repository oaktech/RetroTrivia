//
//  HandoffView.swift
//  RetroTrivia
//

import SwiftUI

struct HandoffView: View {
    @Environment(AudioManager.self) var audioManager
    @Environment(\.horizontalSizeClass) private var sizeClass
    let playerName: String
    let playerColor: Color
    let onReady: () -> Void

    private var metrics: LayoutMetrics {
        LayoutMetrics(horizontalSizeClass: sizeClass)
    }

    var body: some View {
        ZStack {
            // Full-screen player color background
            playerColor
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Hand raised icon - indicates "it's your turn"
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: metrics.handoffIconSize))
                    .foregroundStyle(.white)
                    .opacity(0.9)

                VStack(spacing: 16) {
                    Text("Pass to")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))

                    Text(playerName)
                        .font(.system(size: metrics.handoffNameFont, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 4)
                }

                VStack(spacing: 8) {
                    Text("Look away, other players!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .italic()
                }

                Spacer()

                // Ready button
                Button(action: {
                    audioManager.playSoundEffect(named: "button-tap")
                    onReady()
                }) {
                    HStack(spacing: 12) {
                        Text("READY")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(playerColor)

                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(playerColor)
                    }
                    .frame(maxWidth: metrics.handoffMaxWidth)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: playerColor.opacity(0.4), radius: 12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
            .frame(maxWidth: metrics.handoffMaxWidth)
        }
    }
}

#Preview {
    HandoffView(playerName: "Sarah", playerColor: Color("NeonPink"), onReady: {})
        .environment(AudioManager.shared)
}
