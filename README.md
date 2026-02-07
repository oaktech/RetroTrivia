# RetroTrivia

An iOS trivia game themed around 80s music, built with SwiftUI.

## Features

- **80s Music Trivia** - Questions about Madonna, Michael Jackson, Prince, Whitney Houston, Duran Duran, and more
- **Candy Crush-style Progress Map** - Vertical map where correct answers move you up, wrong answers move you down
- **Retro Aesthetic** - Neon colors, bold typography, and 80s vibes
- **Haptic Feedback** - Satisfying feedback on correct and wrong answers
- **Celebration Animations** - Confetti for correct answers, shake effect for wrong ones

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
├── Components/      # RetroButton, RetroGradientBackground
├── Data/            # questions.json
└── Assets.xcassets/ # Colors and images
```

## Development

See `BUILD_PROMPTS.md` for staged build instructions. The project is designed to be built incrementally across 8 stages, from data models through final polish.

## License

MIT
