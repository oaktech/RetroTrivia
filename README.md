# Retro Trivia Blast

🎮 An iOS trivia game themed around 80s music, built with SwiftUI. Climb a vertical progress map by answering questions about Madonna, Prince, Michael Jackson, and more iconic 80s artists.

**Available on the App Store:** [Retro Trivia Blast](https://apps.apple.com/app/retro-trivia-blast) | **Built with:** [Claude Code](https://claude.ai/code)

## ✨ Features

### Content
- **6,000+ Curated Trivia Questions** - Carefully calibrated difficulty levels (Easy 30%, Medium 24%, Hard 46%)
- **Iconic 80s Artists & Hits** - Madonna, Prince, Michael Jackson, Whitney Houston, U2, Duran Duran, The Police, and 30+ more
- **Smart Question Selection** - Difficulty filtering, automatic deduplication, never repeat questions in a session

### Gameplay Modes
- **Single-Player Mode** - Climb the vertical progress map at your own pace
- **Leaderboard Mode** - 2-minute timed competitive mode with Game Center integration
- **Lives Mode** - Play with 3 lives - answer incorrectly and lose a life, game ends when you run out
- **Pass & Play Multiplayer** - Local 2-4 player same-device mode with turn-based gameplay and final standings

### Visual & Audio
- **Retro 80s Aesthetic** - Neon pink, electric blue, hot magenta colors with bold typography
- **Progressive Tier System** - 9 distinct achievement tiers with escalating visual intensity
- **Level-Up Celebrations** - Spectacular particle burst animations when reaching new tiers
- **Dynamic Music System** - Separate synthwave tracks for menu and gameplay
- **Comprehensive Sound Effects** - Audio feedback for correct/wrong answers, button taps, level-ups
- **Haptic Feedback** - Satisfying tactile feedback throughout gameplay

### Gameplay Features
- **Candy Crush-style Progress Map** - Vertical map where correct answers move you up, wrong answers move you down (floor is level 0)
- **Countdown Timer** - Built-in per-question timer with urgency effects (pulsing at 30s/20s/10s)
- **Game Center Leaderboard** - Global competitive rankings
- **Badge Achievement System** - Unlock badges for various milestones and challenges
- **Persistent Progress** - High score tracking across sessions
- **Difficulty Selection** - Filter questions by Easy, Medium, or Hard

### Technical Highlights
- **CloudKit Question Delivery** - 6,000+ questions from cloud with intelligent random sampling
- **Smart Fallback Strategy** - CloudKit → Local Cache (app always playable)
- **Modern Swift Concurrency** - Async/await, MainActor safety, observation pattern
- **Zero Dependencies** - Pure SwiftUI, no third-party libraries

## 🎯 Gameplay

Answer 80s music trivia questions to climb the vertical progress map. Each correct answer advances you one level, each wrong answer moves you back one level.

**Game Modes:**
- **Leaderboard Mode** - 2-minute timed speed game. Tap the trophy icon to enable and compete globally on Game Center.
- **Practice Mode** - Play at your own pace without time pressure or scoring.
- **Lives Mode** - Start with 3 lives. Each wrong answer costs a life. Game ends when lives run out (adds urgency and challenge).
- **Pass & Play** - 2-4 players on one device. Take turns answering questions, see final standings with medal rankings.

As you progress, map visuals evolve with thickening lines and shifting colors from Electric Blue → Neon Pink → Hot Magenta, creating escalating visual excitement.

## 📱 Requirements

- iOS 17.0+
- Xcode 15.0+
- iCloud account (optional, for CloudKit questions and Game Center leaderboard)

## 🚀 Getting Started

1. Clone the repository
2. Open `RetroTrivia.xcodeproj` in Xcode
3. Select a simulator or device
4. Build and run: `Cmd+R`

### Running Tests
```bash
xcodebuild test -scheme RetroTrivia -destination 'platform=iOS Simulator,name=iPhone 16'
# Or press Cmd+U in Xcode
```

## 📁 Project Structure

```
RetroTriviaiOS/
├── Models/               # GameState, PassAndPlaySession, TriviaQuestion, GameSettings, Badge
├── Views/                # HomeView, GameMapView, PassAndPlayMapView, TriviaGameView
│                         # Overlays: CelebrationOverlay, WrongAnswerOverlay, LevelUpOverlay
│                         # FinalStandingsView, SettingsView, GameCenterLeaderboardView
├── Components/           # RetroButton, RetroGradientBackground, CountdownTimerView
├── Services/             # QuestionManager, CloudKitQuestionService, QuestionCacheManager
├── Managers/             # AudioManager, GameCenterManager, BadgeManager
├── Extensions/           # TriviaQuestion+CloudKit
├── Audio/                # Background music (menu, gameplay) and sound effects
├── Data/                 # questions.json (6,008 questions, bundled)
└── Assets.xcassets/      # Colors, images, app icon
```

## 🏗️ Architecture

**State Management:**
- `@Observable` pattern for reactive state (iOS 17+)
- `@MainActor` for thread safety
- Environment injection for dependency access
- UserDefaults for persistence

**Question Delivery:**
1. **Primary**: CloudKit random sampling (efficient for 6K+ questions)
2. **Fallback**: Local cache for offline play
3. **Emergency**: Bundled questions.json (app always playable)

**Data Flow:** RetroTriviaApp → ContentView → Views & Services → State mutations → Persistence

See `CLAUDE.md` for detailed architecture documentation.

## 🎵 Credits

**Menu Music:** "Electric Lullaby" by Electronic Senses
**Gameplay Music:** "Retro" by jiglr

See `CREDITS.md` for complete music, sound effects, and asset attribution.

## 📋 Privacy & Legal

[Privacy Policy](https://gist.github.com/oaktech/dc4d99c3a4115ba743df84e3834dc03e) | [MIT License](LICENSE)

---

Built with ❤️ and 80s nostalgia. 🎸🎹
