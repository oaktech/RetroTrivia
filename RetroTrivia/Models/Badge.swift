//
//  Badge.swift
//  RetroTrivia
//

import Foundation

struct Badge: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let iconColor: String  // Asset color name e.g. "NeonPink"

    static let all: [Badge] = [
        // Progress
        Badge(id: "level_5",  title: "Rising Star",      description: "Reach level 5",         iconName: "star.fill",          iconColor: "NeonYellow"),
        Badge(id: "level_10", title: "Radical!",          description: "Reach level 10",        iconName: "star.circle.fill",   iconColor: "ElectricBlue"),
        Badge(id: "level_15", title: "Totally Tubular",   description: "Reach level 15",        iconName: "bolt.fill",          iconColor: "NeonPink"),
        Badge(id: "level_20", title: "Bodacious",         description: "Reach level 20",        iconName: "flame.fill",         iconColor: "HotMagenta"),
        Badge(id: "level_25", title: "Ultimate Master",   description: "Reach the summit (level 25)", iconName: "crown.fill", iconColor: "NeonYellow"),
        // Streaks
        Badge(id: "streak_5",  title: "On Fire",    description: "5 correct in a row",   iconName: "flame.fill",       iconColor: "HotMagenta"),
        Badge(id: "streak_10", title: "Hot Streak", description: "10 correct in a row",  iconName: "bolt.circle.fill", iconColor: "ElectricBlue"),
        // Mode
        Badge(id: "first_play",        title: "Play Ball",        description: "Complete your first ranked game",            iconName: "trophy.fill",      iconColor: "NeonYellow"),
        Badge(id: "first_gauntlet",    title: "Into the Gauntlet", description: "Complete your first Gauntlet",             iconName: "shield.fill",      iconColor: "ElectricBlue"),
        Badge(id: "gauntlet_flawless", title: "Flawless Victory",  description: "Finish Gauntlet with all 3 lives",         iconName: "heart.fill",       iconColor: "NeonPink"),
        Badge(id: "gauntlet_survivor", title: "Last Stand",        description: "Finish Gauntlet with exactly 1 life",      iconName: "heart.slash.fill", iconColor: "HotMagenta"),
        // Dedication
        Badge(id: "games_10", title: "Can't Stop Won't Stop", description: "Play 10 games", iconName: "repeat.circle.fill", iconColor: "ElectricBlue"),
        Badge(id: "games_25", title: "Dedicated",             description: "Play 25 games", iconName: "medal.fill",         iconColor: "NeonYellow"),
        // Hard mode
        Badge(id: "gauntlet_hard", title: "Hardcore", description: "Complete Gauntlet on Hard difficulty", iconName: "exclamationmark.triangle.fill", iconColor: "HotMagenta"),
    ]

    static func find(id: String) -> Badge? {
        all.first { $0.id == id }
    }
}
