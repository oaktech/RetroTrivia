# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RetroTrivia is an iOS trivia game built with SwiftUI, themed around 80s music. It features a Candy Crush-style vertical progress map where correct answers move the player up and wrong answers move them down.

**Tech stack**: SwiftUI, iOS 17+, UserDefaults for progress, bundled JSON for questions. No third-party dependencies.

## Build & Run Commands

```bash
# Build the project
xcodebuild -scheme RetroTrivia -destination 'generic/platform=iOS'

# Run tests
xcodebuild test -scheme RetroTrivia -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode: Cmd+R to run, Cmd+U to test
```

## Architecture

The project follows a staged build approach documented in `BUILD_PROMPTS.md`. Key architectural decisions:

**Directory structure** (as implementation progresses):
- `Models/` - TriviaQuestion (Codable struct), GameState (ObservableObject with UserDefaults persistence)
- `Views/` - HomeView, GameMapView, TriviaGameView, overlay views
- `Components/` - RetroButton, RetroGradientBackground
- `Data/` - questions.json (bundled trivia questions)

**Data flow**:
- GameState is injected via environment from ContentView
- Questions loaded from bundled JSON via `TriviaQuestion.loadFromBundle()`
- Position persists to UserDefaults on change

**Navigation**:
```
HomeView → GameMapView → TriviaGameView (sheet) → Overlay → dismiss back to map
```

## Design System

80s retro aesthetic with these color constants:
- NeonPink: #FF10F0
- ElectricBlue: #00D4FF
- HotMagenta: #FF00AA
- RetroPurple: #2D1B4E (dark background)
- NeonYellow: #FFFF00

## Development Stages

Follow `BUILD_PROMPTS.md` for staged implementation:
1. Models & data foundation (TriviaQuestion, GameState, questions.json)
2. Retro theme & design system (colors, RetroButton, typography)
3. Home screen
4. Trivia gameplay view
5. Haptic feedback
6. Celebration/wrong-answer overlays
7. Candy Crush-style progress map
8. Integration & polish

## Key Implementation Notes

- Use SwiftUI's `.sensoryFeedback()` for haptics (iOS 17+)
- GameState floor is 0 (wrong answers can't go negative)
- Overlay animations auto-dismiss after ~1.5 seconds
- ScrollViewReader keeps current map position in view
- High score updates when currentPosition exceeds highScorePosition
