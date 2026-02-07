//
//  RetroTypography.swift
//  RetroTrivia
//

import SwiftUI

extension View {
    func retroTitle() -> some View {
        self
            .font(.system(size: 42, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color("NeonPink"), Color("HotMagenta")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(color: Color("NeonPink").opacity(0.8), radius: 10)
            .shadow(color: Color("NeonPink").opacity(0.5), radius: 20)
    }

    func retroSubtitle() -> some View {
        self
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundStyle(Color("ElectricBlue"))
            .shadow(color: Color("ElectricBlue").opacity(0.5), radius: 4)
    }

    func retroBody() -> some View {
        self
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
    }

    func retroHeading() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(Color("NeonYellow"))
            .shadow(color: Color("NeonYellow").opacity(0.6), radius: 6)
    }

    func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.5), radius: radius)
    }
}

#Preview {
    ZStack {
        RetroGradientBackground()

        VStack(spacing: 20) {
            Text("RETROTRIVIA")
                .retroTitle()

            Text("80s Music Challenge")
                .retroSubtitle()

            Text("Test your knowledge of the greatest decade in music!")
                .retroBody()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("High Score: 42")
                .retroHeading()
        }
    }
}
