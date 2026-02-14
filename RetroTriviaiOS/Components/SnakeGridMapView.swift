//
//  SnakeGridMapView.swift
//  RetroTrivia
//

import SwiftUI

/// A 5x5 snaking game board that shows all 25 levels without scrolling.
/// Row 1 (bottom): 1→2→3→4→5 (left to right)
/// Row 2: 10←9←8←7←6 (right to left)
/// Row 3: 11→12→13→14→15
/// Row 4: 20←19←18←17←16
/// Row 5 (top): 21→22→23→24→25
struct SnakeGridMapView: View {
    let currentPosition: Int
    let maxLevel: Int
    var playerDots: [Int: [Color]] = [:]  // level -> player colors (for Pass & Play)
    var isMultiplayer: Bool = false

    @State private var spotlightPulse = false

    private let columns = 5
    private let rows = 5

    /// Convert 1-based position (1-25) to grid coordinates (col, row from bottom).
    /// Returns (col 0-4, row 0-4 where row 0 = bottom).
    private func gridPosition(for position: Int) -> (col: Int, row: Int) {
        let p = position - 1  // 0-based
        let row = p / columns
        var col = p % columns
        // Odd rows are reversed (right to left)
        if row % 2 == 1 {
            col = (columns - 1) - col
        }
        return (col, row)
    }

    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let availableHeight = geometry.size.height
            let maxByWidth = (availableWidth - CGFloat(columns + 1) * 12) / CGFloat(columns)
            let maxByHeight = (availableHeight - CGFloat(rows + 1) * 12) / CGFloat(rows)
            let nodeSize: CGFloat = min(min(maxByWidth, maxByHeight), 80)
            let hSpacing = (availableWidth - CGFloat(columns) * nodeSize) / CGFloat(columns + 1)
            let vSpacing = (availableHeight - CGFloat(rows) * nodeSize) / CGFloat(rows + 1)

            ZStack {
                // Draw connectors between adjacent nodes
                Canvas { context, size in
                    for pos in 1..<maxLevel {
                        let from = gridPosition(for: pos)
                        let to = gridPosition(for: pos + 1)

                        let fromX = hSpacing + CGFloat(from.col) * (nodeSize + hSpacing) + nodeSize / 2
                        // Flip Y so row 0 is at the bottom
                        let fromY = size.height - (vSpacing + CGFloat(from.row) * (nodeSize + vSpacing) + nodeSize / 2)

                        let toX = hSpacing + CGFloat(to.col) * (nodeSize + hSpacing) + nodeSize / 2
                        let toY = size.height - (vSpacing + CGFloat(to.row) * (nodeSize + vSpacing) + nodeSize / 2)

                        var path = Path()
                        path.move(to: CGPoint(x: fromX, y: fromY))
                        path.addLine(to: CGPoint(x: toX, y: toY))

                        let isCompleted = pos < currentPosition
                        let lineColor: Color
                        if isCompleted {
                            let intensity = Double(pos / 3) / Double(25 / 3)
                            if intensity < 0.4 {
                                lineColor = Color("ElectricBlue")
                            } else if intensity < 0.7 {
                                lineColor = Color("NeonPink")
                            } else {
                                lineColor = Color("HotMagenta")
                            }
                        } else {
                            lineColor = .white.opacity(0.15)
                        }

                        context.stroke(
                            path,
                            with: .color(lineColor.opacity(isCompleted ? 0.8 : 0.3)),
                            lineWidth: isCompleted ? 3 : 1.5
                        )
                    }
                }

                // Place nodes
                ForEach(1...maxLevel, id: \.self) { position in
                    let grid = gridPosition(for: position)
                    let x = hSpacing + CGFloat(grid.col) * (nodeSize + hSpacing) + nodeSize / 2
                    let y = availableHeight - (vSpacing + CGFloat(grid.row) * (nodeSize + vSpacing) + nodeSize / 2)

                    let dots = playerDots[position] ?? []

                    ZStack {
                        // Breathing spotlight glow for current position
                        if position == currentPosition && !isMultiplayer {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color("NeonPink").opacity(spotlightPulse ? 0.35 : 0.2),
                                            Color("NeonPink").opacity(spotlightPulse ? 0.15 : 0.05),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: nodeSize * (spotlightPulse ? 1.3 : 1.1)
                                    )
                                )
                                .frame(width: nodeSize * 2.8, height: nodeSize * 2.8)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: spotlightPulse)
                        }

                        if isMultiplayer && !dots.isEmpty {
                            // Show player dots for multiplayer
                            MapNodeView(
                                levelIndex: position,
                                isCurrentPosition: false,
                                currentPosition: 0,
                                playerDots: dots,
                                sizeMultiplier: nodeSize / 50
                            )
                        } else {
                            // Standard single-player node
                            MapNodeView(
                                levelIndex: position,
                                isCurrentPosition: position == currentPosition,
                                currentPosition: currentPosition,
                                sizeMultiplier: nodeSize / 50
                            )
                        }

                        // Level number below/above node
                        Text("\(position)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(position <= currentPosition ? 0.6 : 0.25))
                            .offset(y: nodeSize / 2 + 8)
                    }
                    .position(x: x, y: y)
                }
            }
            .onAppear {
                spotlightPulse = true
            }
        }
    }
}

#Preview {
    ZStack {
        Color("RetroPurple").ignoresSafeArea()
        SnakeGridMapView(currentPosition: 12, maxLevel: 25)
            .padding(20)
            .frame(height: 500)
    }
}
