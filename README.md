# RetroTrivia

An iOS trivia game themed around 80s music, built with SwiftUI.

**Vibe coded in 1 day using [Claude Code](https://claude.ai/code).** Available on the App Store as [Retro Trivia Blast](https://apps.apple.com/app/retro-trivia-blast).

## Features

- **80s Music Trivia** - Questions about Madonna, Michael Jackson, Prince, Whitney Houston, Duran Duran, and more
- **Candy Crush-style Progress Map** - Vertical map where correct answers move you up, wrong answers move you down
- **Game Center Leaderboard** - Compete globally with 2-minute timed leaderboard mode
- **Lives System** - Optional lives mode (1/2/3/5 lives) for added challenge
- **Progressive Intensity System** - Visual effects and colors intensify as you climb higher, with 9 distinct tier levels
- **Urgency Effects** - Escalating visual tension at 30s, 20s, and 10s remaining with pulsing timer and screen vignette
- **Level-Up Celebrations** - Spectacular particle burst animations when reaching new tiers
- **Countdown Timer** - Optional per-question timer to keep the pace up
- **Retro Aesthetic** - Neon colors, bold typography, and authentic 80s vibes
- **Dynamic Music System** - Separate synthwave tracks for menu and gameplay
- **Comprehensive Sound Effects** - Audio feedback for answers, buttons, and level-ups
- **Haptic Feedback** - Satisfying tactile feedback throughout
- **Celebration Animations** - Confetti explosions for correct answers, shake effect for wrong ones

## Gameplay

Answer 80s music trivia questions to climb the vertical progress map. Correct answers move you up, wrong answers move you down (but never below level 0).

**Game Modes:**
- **Leaderboard Mode** - 2-minute timed game with scores submitted to Game Center. Tap the trophy icon to enable and compete globally.
- **Practice Mode** - Play at your own pace without time pressure.
- **Lives Mode** - Enable lives (1/2/3/5) in Settings for an extra challenge. Game ends when you run out!

**Tier System:**
Every 3 levels, you advance to a new tier with increasing visual intensity:
- **Level 1-2**: Beginner (Electric Blue)
- **Level 3-5**: Rising Star
- **Level 6-8**: On Fire
- **Level 9-11**: Hot Streak (Neon Pink)
- **Level 12-14**: Supercharged
- **Level 15-17**: Elite
- **Level 18-20**: Champion (Hot Magenta)
- **Level 21-23**: Legendary
- **Level 24-25**: Ultimate Master

As you progress, the map's connecting lines grow thicker and colors shift from Electric Blue → Neon Pink → Hot Magenta, creating a sense of escalating excitement.

## Requirements

- iOS 17.0+
- Xcode 15.0+

## Getting Started

1. Clone the repository
2. Open `RetroTrivia.xcodeproj` in Xcode
3. Select a simulator or device
4. Build and run (Cmd+R)

## Project Structure

```
RetroTrivia/
├── Models/          # TriviaQuestion, GameState, GameSettings
├── Views/           # HomeView, GameMapView, TriviaGameView, GameCenterLeaderboardView
│                    # MapNodeView, CelebrationOverlay, WrongAnswerOverlay, LevelUpOverlay
├── Components/      # RetroButton, RetroGradientBackground, RetroTypography
├── Managers/        # AudioManager, GameCenterManager, QuestionManager
├── Audio/           # Background music and sound effects
├── Data/            # questions.json
└── Assets.xcassets/ # Colors, images, and app icon
```

## Development

See `BUILD_PROMPTS.md` for staged build instructions. The project is designed to be built incrementally across 8 stages, from data models through final polish.

## Credits

**Menu Music:** "Electric Lullaby" by Electronic Senses
**Gameplay Music:** "Retro" by jiglr

See `CREDITS.md` for full music, sound effects, and asset attribution.

## Privacy Policy

[Privacy Policy](https://gist.github.com/oaktech/dc4d99c3a4115ba743df84e3834dc03e)

## License

MIT
