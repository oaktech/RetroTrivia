//
//  LEDClockTimerView.swift
//  RetroTrivia
//

import SwiftUI
import Combine

struct LEDClockTimerView: View {
    let timeRemaining: Double
    let totalTime: Double

    @State private var colonVisible = true

    private var fraction: Double { max(0, min(1, timeRemaining / totalTime)) }

    private var activeColor: Color {
        if fraction > 0.5 { return Color("ElectricBlue") }
        if fraction > 0.25 { return Color("NeonYellow") }
        return Color("NeonPink")
    }

    private var totalSec: Int { max(0, Int(timeRemaining)) }
    private var minuteDigit: Int { totalSec / 60 }
    private var tenSecDigit: Int { (totalSec % 60) / 10 }
    private var secDigit: Int { totalSec % 10 }

    var body: some View {
        ZStack {
            // Outer bezel
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.06), Color(white: 0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            // Inner screen
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(white: 0.015))
                .padding(8)

            // LED digits + colon
            HStack(spacing: 6) {
                LEDDigitView(digit: minuteDigit, color: activeColor)

                LEDColonView(visible: colonVisible, color: activeColor)
                    .frame(width: 16)

                LEDDigitView(digit: tenSecDigit, color: activeColor)
                    .padding(.leading, 2)
                LEDDigitView(digit: secDigit, color: activeColor)
            }
            .shadow(color: activeColor.opacity(0.5), radius: 10)
            .shadow(color: activeColor.opacity(0.25), radius: 20)

            // CRT scanline overlay
            Canvas { context, size in
                for y in stride(from: CGFloat(0), through: size.height, by: 2) {
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(line, with: .color(.black.opacity(0.06)), lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(8)
            .allowsHitTesting(false)
        }
        .frame(width: 250, height: 100)
        .shadow(color: activeColor.opacity(0.3), radius: 16)
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            colonVisible.toggle()
        }
    }
}

// MARK: - Seven-Segment Digit

private struct LEDDigitView: View {
    let digit: Int
    let color: Color

    //  aaa
    // f   b
    // f   b
    //  ggg
    // e   c
    // e   c
    //  ddd
    private static let segments: [[Bool]] = [
        //   a      b      c      d      e      f      g
        [true,  true,  true,  true,  true,  true,  false], // 0
        [false, true,  true,  false, false, false, false], // 1
        [true,  true,  false, true,  true,  false, true],  // 2
        [true,  true,  true,  true,  false, false, true],  // 3
        [false, true,  true,  false, false, true,  true],  // 4
        [true,  false, true,  true,  false, true,  true],  // 5
        [true,  false, true,  true,  true,  true,  true],  // 6
        [true,  true,  true,  false, false, false, false], // 7
        [true,  true,  true,  true,  true,  true,  true],  // 8
        [true,  true,  true,  true,  false, true,  true],  // 9
    ]

    var body: some View {
        Canvas { context, size in
            let W = size.width
            let H = size.height
            let T: CGFloat = 7       // segment thickness
            let G: CGFloat = 2       // gap between adjacent segments
            let H2 = H / 2
            let R = T / 3            // corner radius

            let active = Self.segments[max(0, min(9, digit))]

            // Segment rects ordered: a, b, c, d, e, f, g
            let rects: [CGRect] = [
                CGRect(x: T + G,  y: 0,            width: W - 2*T - 2*G, height: T),           // a: top
                CGRect(x: W - T,  y: T + G,        width: T, height: H2 - T - G * 1.5),        // b: top-right
                CGRect(x: W - T,  y: H2 + G * 0.5, width: T, height: H2 - T - G * 1.5),       // c: bottom-right
                CGRect(x: T + G,  y: H - T,        width: W - 2*T - 2*G, height: T),           // d: bottom
                CGRect(x: 0,      y: H2 + G * 0.5, width: T, height: H2 - T - G * 1.5),       // e: bottom-left
                CGRect(x: 0,      y: T + G,        width: T, height: H2 - T - G * 1.5),        // f: top-left
                CGRect(x: T + G,  y: H2 - T / 2,   width: W - 2*T - 2*G, height: T),          // g: middle
            ]

            for (i, rect) in rects.enumerated() {
                let isOn = active[i]
                let segColor = isOn ? color : color.opacity(0.04)
                let path = RoundedRectangle(cornerRadius: R).path(in: rect)
                context.fill(path, with: .color(segColor))
            }
        }
        .frame(width: 46, height: 72)
    }
}

// MARK: - Blinking Colon

private struct LEDColonView: View {
    let visible: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 2)
                .fill(visible ? color : color.opacity(0.04))
                .frame(width: 7, height: 7)
            RoundedRectangle(cornerRadius: 2)
                .fill(visible ? color : color.opacity(0.04))
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color("RetroPurple").ignoresSafeArea()
        VStack(spacing: 30) {
            LEDClockTimerView(timeRemaining: 150, totalTime: 180)
            LEDClockTimerView(timeRemaining: 45, totalTime: 180)
            LEDClockTimerView(timeRemaining: 12, totalTime: 180)
        }
    }
}
