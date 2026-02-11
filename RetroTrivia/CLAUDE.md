# CLAUDE.md - Retro Trivia Blast Development Guide

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## Project Overview

**Retro Trivia Blast** is a production iOS trivia game built with SwiftUI, themed around 80s music. It features a Candy Crush-style vertical progress map where correct answers move the player up and wrong answers move them down.

**Tech Stack:**
- SwiftUI (iOS 17+)
- CloudKit for 6,008 questions (public database)
- UserDefaults for player progress
- Bundled question fallback for offline play
- Game Center leaderboard integration
- No third-party dependencies

**Status:** Complete and App Store published - focus on bug fixes and feature polish.

## Git Workflow

**IMPORTANT: Commit frequently!**

Create a git commit after:
- Each completed feature or bug fix
- Significant refactoring
- Architecture improvements
- Before starting new work

Use descriptive commit messages:
- First line: Brief summary (50 chars or less)
- Body: Bullet points describing changes
- Footer: `Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>`

## Build & Run Commands

```bash
# Build for iOS
xcodebuild -scheme RetroTrivia -destination 'generic/platform=iOS'

# Run unit tests
xcodebuild test -scheme RetroTrivia -destination 'platform=iOS Simulator,name=iPhone 16'

# Or in Xcode
Cmd+R     # Build and run
Cmd+U     # Run tests
Cmd+B     # Build only
```

## Current Architecture

### Core Models
- **GameState** (@Observable, @MainActor) - Single-player game progress, persisted to UserDefaults
- **PassAndPlaySession** - Multiplayer (2-4 players) local game state, positions, turn tracking
- **TriviaQuestion** - Trivia data structure with difficulty, category
- **GameSettings** - User preferences (lives mode, difficulty, timer settings)
- **Badge** - Achievement system

### Services Layer
- **QuestionManager** (@Observable) - Question pool management with CloudKit primary, cache fallback, bundled emergency fallback
- **CloudKitQuestionService** - CloudKit public database queries with random sampling
- **AudioManager** (singleton) - Menu/gameplay music, sound effects, haptics
- **GameCenterManager** (singleton) - Leaderboard submission, authentication
- **BadgeManager** (singleton) - Achievement tracking and unlocking

### View Architecture
- **ContentView** - Root navigation orchestrator
- **HomeView** - Main menu with game mode selection
- **GameMapView** - Single-player progress map with node interactions
- **PassAndPlayMapView** - Multiplayer map with turn orchestration
- **TriviaGameView** - Question display and answer selection (full-screen overlay)
- **Overlay Views** - CelebrationOverlay, WrongAnswerOverlay, LevelUpOverlay, etc.
- **Components** - RetroButton, RetroGradientBackground, CountdownTimerView

### Data Flow
```
RetroTriviaApp (@State managers)
    ↓
ContentView (environment injection)
    ↓
Views & Services (@Environment access)
    ↓
State mutations via @Observable didSet
    ↓
UserDefaults/CloudKit persistence
```

### Question Loading Strategy
1. **Primary**: CloudKit random sampling (1-6008 range)
2. **Fallback**: QuestionCacheManager (offline support)
3. **Emergency**: Bundled questions.json (app always playable)

Session tracks `askedQuestionIDs` per game (Set<String>) to prevent repeats within a session.

## Design System

**80s Retro Aesthetic** - Neon colors, bold typography, particle effects

Color Constants:
- NeonPink: #FF10F0 (winner highlight, accents)
- ElectricBlue: #00D4FF (primary, lower tiers)
- HotMagenta: #FF00AA (upper tier intensity)
- RetroPurple: #2D1B4E (dark background)
- NeonYellow: #FFFF00 (accent, tier badges)

**Typography:**
- System font with rounded design
- .black weight for titles
- .semibold for headers
- .system for body text

## Key Implementation Notes

### Performance & Best Practices
- Use SwiftUI's `.sensoryFeedback()` for haptics (iOS 17+ native)
- @MainActor ensures all state mutations on main thread
- GameState floor is 0 (position never goes negative)
- Overlay animations auto-dismiss after ~1.5 seconds
- ScrollViewReader maintains map scroll position during gameplay
- High score updates when currentPosition exceeds highScorePosition

### CloudKit Integration
- Random sampling via sortOrder field (1-6008)
- Rate limiting: 200 questions per batch with 500ms delay
- Graceful fallback: CloudKit → Cache → Bundled
- Network errors are recoverable (user continues with cached/bundled)

### Multiplayer (Pass & Play)
- 2-4 players, same device only
- Turn-based orchestration via PassAndPlayMapView
- No networking or persistence between sessions
- Final standings sorted by: position → correctAnswers → player order
- HandoffView full-screen interstitial between turns

### State Management
- Avoid @State in most views (use @Environment for @Observable objects)
- Only use @State for local UI state (sheet visibility, picker selection)
- Never pass non-Observable data through environment
- didSet observers handle persistence automatically

## Important Files to Know

- `RetroTriviaApp.swift` - App entry, environment setup, scene phase handling
- `Models/GameState.swift` - Core single-player state machine
- `Models/PassAndPlaySession.swift` - Multiplayer state model
- `Services/QuestionManager.swift` - Question pool orchestration
- `Services/CloudKitQuestionService.swift` - CloudKit queries
- `Audio/AudioManager.swift` - Sound effects and music
- `Views/GameMapView.swift` - Single-player UI
- `Views/PassAndPlayMapView.swift` - Multiplayer UI
- `.gitignore` - Protected: questions.json, Scripts/, xcuserdata/, .DS_Store

## Known Limitations & Considerations

- No undo/replay system (future: could implement action reducer pattern)
- Tests minimal (recommend unit tests for GameState logic)
- View components could be smaller (some exceed 150 lines)
- Consider MVVM-C for future architectural refactoring
- CloudKit random sampling scales well to 6,008 questions

## Useful Commands for Debugging

```bash
# Check what's in git (for accidental commits)
git ls-files | grep -E "json|Scripts"

# View commit history for a file
git log --oneline -- path/to/file

# Show environment variables in app
lldb> po ProcessInfo.processInfo.environment
```
