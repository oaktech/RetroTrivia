//
//  RetroGradientBackground.swift
//  RetroTrivia
//

import SwiftUI

struct RetroGradientBackground: View {
    var showGrid: Bool = true

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color("RetroPurple"),
                    Color("RetroPurple").opacity(0.8),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            if showGrid {
                GridOverlay()
                    .opacity(0.25)
            }
        }
        .ignoresSafeArea()
    }
}

struct GridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let gridSpacing: CGFloat = 40
            let lineWidth: CGFloat = 1

            // Vertical lines
            for x in stride(from: 0, through: size.width, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Color("NeonPink")), lineWidth: lineWidth)
            }

            // Horizontal lines
            for y in stride(from: 0, through: size.height, by: gridSpacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Color("ElectricBlue")), lineWidth: lineWidth)
            }
        }
    }
}

#Preview {
    RetroGradientBackground()
}
