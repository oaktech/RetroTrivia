#if DEBUG
//
//  DebugBadgePanelView.swift
//  RetroTrivia
//

import SwiftUI

struct DebugBadgePanelView: View {
    @Environment(BadgeManager.self) var badgeManager
    let onUnlock: ([Badge]) -> Void
    @Environment(\.dismiss) private var dismiss

    private let categories: [(String, [String])] = [
        ("Progress",   ["level_5", "level_10", "level_15", "level_20", "level_25"]),
        ("Streaks",    ["streak_5", "streak_10"]),
        ("Mode",       ["first_play", "first_gauntlet", "gauntlet_flawless", "gauntlet_survivor", "gauntlet_hard"]),
        ("Dedication", ["games_10", "games_25"]),
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Unlock All") {
                        var newBadges: [Badge] = []
                        for badge in Badge.all {
                            newBadges += badgeManager.forceUnlock(badge.id)
                        }
                        if !newBadges.isEmpty { onUnlock(newBadges) }
                    }
                    Button("Reset All", role: .destructive) {
                        badgeManager.resetAll()
                    }
                }

                ForEach(categories, id: \.0) { (category, ids) in
                    Section(category) {
                        ForEach(ids, id: \.self) { id in
                            if let badge = Badge.find(id: id) {
                                BadgeDebugRow(badge: badge, isUnlocked: badgeManager.isUnlocked(id)) {
                                    let newBadges = badgeManager.forceUnlock(id)
                                    if !newBadges.isEmpty { onUnlock(newBadges) }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Badge Debug")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct BadgeDebugRow: View {
    let badge: Badge
    let isUnlocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: badge.iconName)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(badge.title)
                    .font(.headline)
                Text(badge.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Unlock", action: onUnlock)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}
#endif
