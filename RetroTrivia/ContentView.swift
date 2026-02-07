//
//  ContentView.swift
//  RetroTrivia
//
//  Created by Craig Oaks on 2/4/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(GameState.self) var gameState
    @State private var showGameMap = false

    var body: some View {
        if showGameMap {
            GameMapView(onBackTapped: {
                showGameMap = false
            })
        } else {
            HomeView(onPlayTapped: {
                showGameMap = true
            })
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}
