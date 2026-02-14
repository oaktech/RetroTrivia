//
//  StageSpotlightOverlay.swift
//  RetroTrivia
//

import SwiftUI

/// Layered atmospheric background for iPad game screens.
/// Adds spotlight, vignette, and stage floor effects on top of RetroGradientBackground.
struct StageSpotlightOverlay: View {
    var spotlightRadius: CGFloat = 500
    var spotlightOpacity: Double = 0.03
    var vignetteOpacity: Double = 0.4
    var stageFloorOpacity: Double = 0.08

    var body: some View {
        ZStack {
            // Layer 2: Radial spotlight from top-center
            RadialGradient(
                colors: [
                    Color.white.opacity(spotlightOpacity),
                    Color.white.opacity(spotlightOpacity * 0.5),
                    Color.clear
                ],
                center: UnitPoint(x: 0.5, y: 0.15),
                startRadius: 0,
                endRadius: spotlightRadius
            )
            .ignoresSafeArea()

            // Layer 3: Edge vignette — darker at edges, transparent center
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(vignetteOpacity * 0.5),
                    Color.black.opacity(vignetteOpacity)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 800
            )
            .ignoresSafeArea()

            // Layer 4: Stage floor — subtle warm hint at very bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color("NeonPink").opacity(stageFloorOpacity * 0.5),
                        Color("NeonPink").opacity(stageFloorOpacity)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            .ignoresSafeArea()
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        RetroGradientBackground()
        StageSpotlightOverlay()
    }
}
