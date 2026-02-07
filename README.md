# RetroTrivia

An iOS trivia game themed around 80s music, built with SwiftUI.

## Features

- **80s Music Trivia** - Questions about Madonna, Michael Jackson, Prince, Whitney Houston, Duran Duran, and more
- **Candy Crush-style Progress Map** - Vertical map where correct answers move you up, wrong answers move you down
- **Progressive Intensity System** - Visual effects and colors intensify as you climb higher, with 9 distinct tier levels
- **Level-Up Celebrations** - Spectacular particle burst animations when reaching new tiers (Rising Star, On Fire, Hot Streak, Elite, Champion, Legendary, and more)
- **Retro Aesthetic** - Neon colors, bold typography, and authentic 80s vibes
- **Dynamic Music System** - Separate synthwave tracks for menu and gameplay that switch automatically
- **Comprehensive Sound Effects** - Audio feedback for correct/wrong answers, button clicks, music toggles, and level-ups
- **Audio Controls** - Toggle music and sound effects on/off with persistent settings
- **Haptic Feedback** - Satisfying tactile feedback on correct and wrong answers
- **Celebration Animations** - Confetti explosions for correct answers, shake effect for wrong ones
- **Quit Confirmation** - Safety dialog to prevent accidental exits from the game

## Gameplay

Answer 80s music trivia questions to climb the vertical progress map. Correct answers move you up, wrong answers move you down (but never below level 0).

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
├── Models/          # TriviaQuestion, GameState
├── Views/           # HomeView, GameMapView, TriviaGameView
│                    # MapNodeView, CelebrationOverlay, WrongAnswerOverlay, LevelUpOverlay
├── Components/      # RetroButton, RetroGradientBackground, RetroTypography
├── Audio/           # AudioManager, background music (menu-music.mp3, gameplay-music.mp3)
│                    # Sound effects (correct-answer.wav, wrong-answer.wav, etc.)
├── Data/            # questions.json
└── Assets.xcassets/ # Colors (NeonPink, ElectricBlue, HotMagenta, etc.) and images
```

## Development

See `BUILD_PROMPTS.md` for staged build instructions. The project is designed to be built incrementally across 8 stages, from data models through final polish.

## Credits

**Menu Music:** "Electric Lullaby" by Electronic Senses
**Gameplay Music:** "Retro" by jiglr

See `CREDITS.md` for full music, sound effects, and asset attribution.

## License

MIT
