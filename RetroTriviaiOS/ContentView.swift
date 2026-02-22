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
    @State private var showDailyChallenge = false
    @State private var passAndPlaySession: PassAndPlaySession?

    var body: some View {
        if showGameMap {
            GameMapView(onBackTapped: {
                showGameMap = false
            })
        } else if showDailyChallenge {
            DailyChallengeView(onDone: {
                showDailyChallenge = false
            })
        } else if let session = passAndPlaySession {
            PassAndPlayMapView(session: session, onDone: {
                passAndPlaySession = nil
            })
        } else {
            HomeView(
                onPlayTapped: {
                    showGameMap = true
                },
                onDailyChallengeTapped: {
                    showDailyChallenge = true
                },
                onPassAndPlayTapped: { session in
                    passAndPlaySession = session
                }
            )
        }
    }
}

#Preview {
    ContentView()
        .environment(GameState())
}
