//
//  ContentView.swift
//  RetroTrivia
//
//  Created by Craig Oaks on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) var gameState

    var body: some View {
        VStack(spacing: 20) {
            Text("RetroTrivia")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Stage 1 Complete")
                .font(.title2)

            Text("Position: \(gameState.currentPosition)")
            Text("High Score: \(gameState.highScorePosition)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}
