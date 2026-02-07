//
//  MapNodeView.swift
//  RetroTrivia
//

import SwiftUI

struct MapNodeView: View {
    let levelIndex: Int
    let isCurrentPosition: Bool
    let currentPosition: Int

    private var nodeState: NodeState {
        if levelIndex == currentPosition {
            return .current
        } else if levelIndex < currentPosition {
            return .completed
        } else {
            return .locked
        }
    }

    var body: some View {
        ZStack {
            // Node circle
            Circle()
                .fill(backgroundColor)
                .frame(width: nodeSize, height: nodeSize)
                .overlay(
                    Circle()
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(color: shadowColor, radius: isCurrentPosition ? 20 : 5)

            // Icon or number
            if nodeState == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color("NeonPink"))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(iconColor)
            }
        }
        .scaleEffect(isCurrentPosition ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isCurrentPosition)
    }

    private var nodeSize: CGFloat {
        isCurrentPosition ? 80 : 60
    }

    private var borderWidth: CGFloat {
        isCurrentPosition ? 4 : 2
    }

    private var backgroundColor: Color {
        switch nodeState {
        case .current:
            return Color("RetroPurple").opacity(0.9)
        case .completed:
            return Color("RetroPurple").opacity(0.6)
        case .locked:
            return Color("RetroPurple").opacity(0.3)
        }
    }

    private var borderColor: Color {
        switch nodeState {
        case .current:
            return Color("NeonPink")
        case .completed:
            return Color("ElectricBlue")
        case .locked:
            return Color.white.opacity(0.3)
        }
    }

    private var iconColor: Color {
        switch nodeState {
        case .current:
            return Color("NeonYellow")
        case .completed:
            return Color("ElectricBlue")
        case .locked:
            return Color.white.opacity(0.4)
        }
    }

    private var shadowColor: Color {
        switch nodeState {
        case .current:
            return Color("NeonPink").opacity(0.8)
        case .completed:
            return Color("ElectricBlue").opacity(0.3)
        case .locked:
            return Color.clear
        }
    }
}

enum NodeState {
    case current
    case completed
    case locked
}

#Preview {
    ZStack {
        Color("RetroPurple")
            .ignoresSafeArea()

        VStack(spacing: 40) {
            MapNodeView(levelIndex: 0, isCurrentPosition: false, currentPosition: 5)
            MapNodeView(levelIndex: 5, isCurrentPosition: true, currentPosition: 5)
            MapNodeView(levelIndex: 10, isCurrentPosition: false, currentPosition: 5)
        }
    }
}
