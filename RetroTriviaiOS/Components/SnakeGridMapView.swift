//
//  SnakeGridMapView.swift
//  RetroTrivia
//

import SwiftUI

/// A 5×5 Candy Crush-style progression board for iPad.
/// Uniform node sizes — visual excitement comes from color, glow, and animation.
/// No MapNodeView dependency — purpose-built grid nodes eliminate overlap.
///
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

    @State private var appeared = false
    @State private var animating = false

    private let columns = 5
    private let rows = 5

    /// Convert 1-based position to grid coordinates (col, row from bottom).
    private func gridCoord(for position: Int) -> (col: Int, row: Int) {
        let p = position - 1
        let row = p / columns
        var col = p % columns
        if row % 2 == 1 { col = (columns - 1) - col }
        return (col, row)
    }

    private enum NodeKind {
        case completed, current, next, locked
    }

    private func nodeKind(for pos: Int) -> NodeKind {
        if pos < currentPosition { return .completed }
        if pos == currentPosition && currentPosition >= 1 { return .current }
        if pos == currentPosition + 1 { return .next }
        return .locked
    }

    /// Tier color progresses: blue → pink → magenta
    private func tierColor(for pos: Int) -> Color {
        let t = Double(pos) / Double(maxLevel)
        if t <= 0.33 { return Color("ElectricBlue") }
        if t <= 0.66 { return Color("NeonPink") }
        return Color("HotMagenta")
    }

    var body: some View {
        GeometryReader { geo in
            let aw = geo.size.width
            let ah = geo.size.height
            let gap: CGFloat = 16
            let mw = (aw - CGFloat(columns + 1) * gap) / CGFloat(columns)
            let mh = (ah - CGFloat(rows + 1) * gap) / CGFloat(rows)
            let ns: CGFloat = min(min(mw, mh), 72)
            let hs = (aw - CGFloat(columns) * ns) / CGFloat(columns + 1)
            let vs = (ah - CGFloat(rows) * ns) / CGFloat(rows + 1)

            ZStack {
                // ── Path Connectors ──
                Canvas { ctx, size in
                    for pos in 1..<maxLevel {
                        let from = gridCoord(for: pos)
                        let to = gridCoord(for: pos + 1)
                        let fx = hs + CGFloat(from.col) * (ns + hs) + ns / 2
                        let fy = size.height - (vs + CGFloat(from.row) * (ns + vs) + ns / 2)
                        let tx = hs + CGFloat(to.col) * (ns + hs) + ns / 2
                        let ty = size.height - (vs + CGFloat(to.row) * (ns + vs) + ns / 2)

                        var path = Path()
                        path.move(to: CGPoint(x: fx, y: fy))
                        path.addLine(to: CGPoint(x: tx, y: ty))

                        if pos < currentPosition {
                            // Completed: thick neon with glow halo
                            let c = tierColor(for: pos)
                            ctx.stroke(path, with: .color(c.opacity(0.2)), lineWidth: 14)
                            ctx.stroke(path, with: .color(c.opacity(0.85)), lineWidth: 4.5)
                        } else if pos == currentPosition {
                            // Current → next: medium, inviting
                            ctx.stroke(path, with: .color(Color.white.opacity(0.2)), lineWidth: 2.5)
                        } else {
                            // Locked: thin dashed
                            let style = StrokeStyle(lineWidth: 1.5, dash: [5, 5])
                            ctx.stroke(path, with: .color(Color.white.opacity(0.08)), style: style)
                        }
                    }
                }

                // ── Nodes ──
                ForEach(1...maxLevel, id: \.self) { pos in
                    let g = gridCoord(for: pos)
                    let x = hs + CGFloat(g.col) * (ns + hs) + ns / 2
                    let y = ah - (vs + CGFloat(g.row) * (ns + vs) + ns / 2)
                    let kind = nodeKind(for: pos)
                    let delay = Double(pos - 1) * 0.03

                    nodeView(pos: pos, kind: kind, size: ns)
                        .position(x: x, y: y)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.15)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.6).delay(delay),
                            value: appeared
                        )
                }
            }
        }
        .onAppear {
            appeared = true
            animating = true
        }
    }

    // MARK: - Node Router

    @ViewBuilder
    private func nodeView(pos: Int, kind: NodeKind, size: CGFloat) -> some View {
        let dots = playerDots[pos] ?? []
        if isMultiplayer && !dots.isEmpty {
            multiplayerNode(pos: pos, dots: dots, isCurrent: kind == .current, size: size)
        } else {
            switch kind {
            case .completed: completedNode(pos: pos, size: size)
            case .current:   currentNode(pos: pos, size: size)
            case .next:      nextNode(pos: pos, size: size)
            case .locked:    lockedNode(pos: pos, size: size)
            }
        }
    }

    // MARK: - Completed Node

    @ViewBuilder
    private func completedNode(pos: Int, size: CGFloat) -> some View {
        let c = tierColor(for: pos)
        ZStack {
            // Soft shimmer halo
            Circle()
                .fill(c.opacity(animating ? 0.16 : 0.06))
                .frame(width: size * 1.35, height: size * 1.35)
                .animation(
                    .easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                    value: animating
                )

            // Filled circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [c.opacity(0.5), c.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(Circle().stroke(c.opacity(0.8), lineWidth: 2.5))
                .shadow(color: c.opacity(0.45), radius: 8)

            // Gold star
            Image(systemName: "star.fill")
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundStyle(Color("NeonYellow"))
                .shadow(
                    color: Color("NeonYellow").opacity(animating ? 0.8 : 0.25),
                    radius: animating ? 6 : 2
                )
                .animation(
                    .easeInOut(duration: 2).repeatForever(autoreverses: true),
                    value: animating
                )

            // Level number
            Text("\(pos)")
                .font(.system(size: size * 0.15, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .offset(y: size * 0.3)
        }
    }

    // MARK: - Current Node

    @ViewBuilder
    private func currentNode(pos: Int, size: CGFloat) -> some View {
        ZStack {
            // Wide spotlight glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("NeonPink").opacity(animating ? 0.35 : 0.12),
                            Color("NeonPink").opacity(animating ? 0.1 : 0.02),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 1.6
                    )
                )
                .frame(width: size * 3.2, height: size * 3.2)
                .animation(
                    .easeInOut(duration: 1.3).repeatForever(autoreverses: true),
                    value: animating
                )

            // Ripple ring — expands outward and fades
            Circle()
                .stroke(Color("NeonPink").opacity(animating ? 0 : 0.4), lineWidth: 2)
                .frame(
                    width: size * (animating ? 2.2 : 1.0),
                    height: size * (animating ? 2.2 : 1.0)
                )
                .animation(
                    .easeOut(duration: 1.8).repeatForever(autoreverses: false),
                    value: animating
                )

            // Core circle with rainbow neon border
            Circle()
                .fill(Color("RetroPurple").opacity(0.85))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    Color("NeonPink"),
                                    Color("ElectricBlue"),
                                    Color("NeonYellow"),
                                    Color("NeonPink")
                                ],
                                center: .center
                            ),
                            lineWidth: 3.5
                        )
                )
                .shadow(color: Color("NeonPink").opacity(0.6), radius: 14)

            // Music note icon
            Image(systemName: "music.note")
                .font(.system(size: size * 0.32, weight: .bold))
                .foregroundStyle(Color("NeonYellow"))
                .shadow(color: Color("NeonYellow").opacity(0.9), radius: 8)

            // Level number
            Text("\(pos)")
                .font(.system(size: size * 0.15, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .offset(y: size * 0.3)
        }
        // Gentle bounce
        .scaleEffect(animating ? 1.08 : 1.0)
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: animating
        )
    }

    // MARK: - Next Node (inviting glow)

    @ViewBuilder
    private func nextNode(pos: Int, size: CGFloat) -> some View {
        ZStack {
            // Breathing halo
            Circle()
                .fill(Color("ElectricBlue").opacity(animating ? 0.12 : 0.02))
                .frame(width: size * 1.3, height: size * 1.3)
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: animating
                )

            // Circle with pulsing border
            Circle()
                .fill(Color("RetroPurple").opacity(0.4))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            Color("ElectricBlue").opacity(animating ? 0.55 : 0.2),
                            lineWidth: 2
                        )
                )
                .animation(
                    .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                    value: animating
                )

            Text("\(pos)")
                .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    // MARK: - Locked Node

    @ViewBuilder
    private func lockedNode(pos: Int, size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1.5))

            Text("\(pos)")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.2))
        }
    }

    // MARK: - Multiplayer Node

    @ViewBuilder
    private func multiplayerNode(pos: Int, dots: [Color], isCurrent: Bool, size: CGFloat) -> some View {
        let primary = dots.first ?? Color("ElectricBlue")
        ZStack {
            if isCurrent {
                // Spotlight for current player
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                primary.opacity(animating ? 0.3 : 0.08),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 1.4
                        )
                    )
                    .frame(width: size * 2.8, height: size * 2.8)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: animating
                    )
            }

            // Node circle
            Circle()
                .fill(Color("RetroPurple").opacity(isCurrent ? 0.7 : 0.3))
                .frame(width: size, height: size)
                .overlay(
                    Circle().stroke(
                        primary.opacity(isCurrent ? 0.7 : 0.3),
                        lineWidth: isCurrent ? 3 : 1.5
                    )
                )
                .shadow(
                    color: isCurrent ? primary.opacity(0.5) : .clear,
                    radius: isCurrent ? 10 : 0
                )

            // Player dots cluster
            HStack(spacing: dots.count > 2 ? -4 : (dots.count > 1 ? -6 : 0)) {
                ForEach(dots.indices, id: \.self) { i in
                    Circle()
                        .fill(dots[i])
                        .frame(width: size * 0.28, height: size * 0.28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                        .shadow(color: dots[i].opacity(0.6), radius: 4)
                }
            }

            // Position number
            Text("\(pos)")
                .font(.system(size: size * 0.14, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .offset(y: size * 0.3)
        }
        .scaleEffect(isCurrent && animating ? 1.06 : 1.0)
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: animating
        )
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
