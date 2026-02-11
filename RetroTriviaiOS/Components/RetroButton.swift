//
//  RetroButton.swift
//  RetroTrivia
//

import SwiftUI

enum RetroButtonVariant {
    case primary
    case secondary
}

struct RetroButton: View {
    let title: String
    let variant: RetroButtonVariant
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, variant: RetroButtonVariant = .primary, action: @escaping () -> Void) {
        self.title = title
        self.variant = variant
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .foregroundStyle(textColor)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderGradient, lineWidth: 3)
                )
                .shadow(color: glowColor.opacity(0.6), radius: isPressed ? 4 : 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var textColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return Color("NeonPink")
        }
    }

    private var background: some ShapeStyle {
        switch variant {
        case .primary:
            return AnyShapeStyle(Color("RetroPurple"))
        case .secondary:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: [Color("NeonPink"), Color("ElectricBlue")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glowColor: Color {
        switch variant {
        case .primary:
            return Color("NeonPink")
        case .secondary:
            return Color("ElectricBlue")
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ScaleButtonContent(configuration: configuration)
    }
}

private struct ScaleButtonContent: View {
    let configuration: ButtonStyleConfiguration
    @State private var glowBrightness: Double = 0

    var body: some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .brightness(glowBrightness)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { wasPressed, isPressed in
                if wasPressed && !isPressed {
                    // Button released — flash brightness
                    glowBrightness = 0.3
                    withAnimation(.easeOut(duration: 0.15)) {
                        glowBrightness = 0
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        Color("RetroPurple")
            .ignoresSafeArea()

        VStack(spacing: 24) {
            RetroButton("Play Now", variant: .primary) {
                print("Primary tapped")
            }

            RetroButton("Settings", variant: .secondary) {
                print("Secondary tapped")
            }
        }
    }
}
