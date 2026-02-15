//
//  AdaptiveLayout.swift
//  RetroTrivia
//

import SwiftUI

struct LayoutMetrics {
    let isIPad: Bool

    init(horizontalSizeClass: UserInterfaceSizeClass?) {
        isIPad = horizontalSizeClass == .regular
    }

    // MARK: - Home Screen

    var appIconSize: CGFloat { isIPad ? 180 : 120 }
    var titleFontSize: CGFloat { isIPad ? 32 : 24 }
    var headerIconFrame: CGFloat { isIPad ? 52 : 42 }
    var headerIconFont: CGFloat { isIPad ? 22 : 18 }
    var homeMaxWidth: CGFloat { isIPad ? 950 : .infinity }
    var gameModeCardVerticalPadding: CGFloat { isIPad ? 24 : 18 }
    var gameModeCardTitleFont: CGFloat { isIPad ? 28 : 22 }
    var gameModeCardDetailFont: CGFloat { isIPad ? 16 : 14 }
    var gameModeCardSubtitle: String? { nil }

    // MARK: - Game Map

    var mapNodeSizeMultiplier: CGFloat { isIPad ? 1.4 : 1.0 }
    var mapNodeSpacing: CGFloat { isIPad ? 130 : 100 }
    var mapSidebarWidth: CGFloat { isIPad ? 220 : 0 }
    var mapZigzagAmplitude: CGFloat { isIPad ? 80 : 0 }
    var mapLineHeightMultiplier: CGFloat { isIPad ? 1.3 : 1.0 }

    // MARK: - Snake Grid (iPad Game Board)

    var snakeGridColumns: Int { 5 }
    var snakeGridRows: Int { 5 }
    var snakeGridNodeSize: CGFloat { 70 }
    var snakeGridSpacing: CGFloat { 12 }

    // MARK: - Trivia Game

    var questionFontSize: CGFloat { isIPad ? 28 : 22 }
    var questionCardMaxWidth: CGFloat { isIPad ? 650 : .infinity }
    var answerAreaMaxWidth: CGFloat { isIPad ? 700 : .infinity }
    var answerFontSize: CGFloat { isIPad ? 20 : 16 }
    var answerVerticalPadding: CGFloat { isIPad ? 24 : 18 }
    var answerTileHeight: CGFloat { isIPad ? 72 : 56 }
    var countdownTimerSize: CGFloat { isIPad ? 96 : 64 }
    var countdownFontSize: CGFloat { isIPad ? 28 : 18 }
    var countdownLineWidth: CGFloat { isIPad ? 7 : 5 }

    // MARK: - Overlays

    var overlayTextScale: CGFloat { isIPad ? 1.5 : 1.0 }
    var overlayIconScale: CGFloat { isIPad ? 1.5 : 1.0 }
    var confettiSpreadMin: CGFloat { isIPad ? -500 : -200 }
    var confettiSpreadMax: CGFloat { isIPad ? 500 : 200 }
    var levelUpBadgeSize: CGFloat { isIPad ? 240 : 160 }
    var particleBurstDistance: CGFloat { isIPad ? 400 : 200 }
    var overlayMaxWidth: CGFloat { isIPad ? 550 : .infinity }
    var gameOverMaxWidth: CGFloat { isIPad ? 650 : .infinity }

    // MARK: - Modals

    var settingsMaxWidth: CGFloat { isIPad ? 500 : .infinity }
    var badgeGridColumns: Int { isIPad ? 3 : 2 }
    var badgeGalleryMaxWidth: CGFloat { isIPad ? 900 : .infinity }
    var passAndPlaySetupMaxWidth: CGFloat { isIPad ? 600 : .infinity }
    var difficultyPickerMaxWidth: CGFloat { isIPad ? 400 : .infinity }
    var handoffMaxWidth: CGFloat { isIPad ? 500 : .infinity }
    var finalStandingsMaxWidth: CGFloat { isIPad ? 700 : .infinity }

    // MARK: - Handoff

    var handoffNameFont: CGFloat { isIPad ? 64 : 48 }
    var handoffIconSize: CGFloat { isIPad ? 120 : 80 }

    // MARK: - Pass & Play Map

    var playerSidebarWidth: CGFloat { isIPad ? 240 : 0 }
    var playerDotSize: CGFloat { isIPad ? 32 : 24 }

    // MARK: - RetroButton

    var buttonMaxWidth: CGFloat { isIPad ? 500 : .infinity }

    // MARK: - Badge Toast

    var badgeToastIconFont: CGFloat { isIPad ? 28 : 24 }
    var badgeToastTitleFont: CGFloat { isIPad ? 17 : 15 }
}
