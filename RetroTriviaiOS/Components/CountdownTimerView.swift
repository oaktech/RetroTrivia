//
//  CountdownTimerView.swift
//  RetroTrivia
//

import SwiftUI

struct CountdownTimerView: View {
    let timeRemaining: Double
    let totalTime: Double

    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var fraction: Double {
        max(0, min(1, timeRemaining / totalTime))
    }

    private var timerColor: Color {
        if fraction > 0.5 { return Color("ElectricBlue") }
        if fraction > 0.25 { return Color("NeonYellow") }
        return Color("NeonPink")
    }

    private var isPulsing: Bool { fraction < 0.25 && !reduceMotion }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: fraction)
                .stroke(timerColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .neonGlow(color: timerColor, radius: 8)
                .animation(.linear(duration: 0.1), value: fraction)

            Text("\(Int(ceil(max(0, timeRemaining))))")
                .font(.custom("Orbitron-Bold", size: 18))
                .monospacedDigit()
                .foregroundStyle(timerColor)
                .neonGlow(color: timerColor, radius: 4)
                .contentTransition(.numericText())
        }
        .frame(width: 64, height: 64)
        .scaleEffect(pulseScale)
        .onChange(of: Int(ceil(timeRemaining))) { _, _ in
            guard isPulsing else { return }
            withAnimation(.easeInOut(duration: 0.15)) {
                pulseScale = 1.08
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color("RetroPurple").ignoresSafeArea()
        HStack(spacing: 40) {
            CountdownTimerView(timeRemaining: 12, totalTime: 15)
            CountdownTimerView(timeRemaining: 5, totalTime: 15)
            CountdownTimerView(timeRemaining: 2, totalTime: 15)
        }
    }
    .environment(AudioManager.shared)
}
