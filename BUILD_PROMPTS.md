# RetroTrivia: Staged Build Prompts

Use these prompts one at a time in order. Each prompt is self-contained and assumes the previous stages are complete. Copy-paste the full prompt for the stage you're on.

---

## Master Context (include in any stage if starting fresh)

**Project**: RetroTrivia — an iOS trivia game (SwiftUI) themed around 80's music. Like Trivia Crack but music-specific.

**Core mechanics**:
- 4 multiple-choice answers per question, 1 correct
- Candy Crush-style vertical progress map: correct = move up, wrong = move down (floor at 0)
- Haptic feedback + celebrations for correct, negative feedback for wrong
- Retro 80s aesthetic: neon colors, bold typography, cassette/vinyl motifs

**Tech stack**: SwiftUI, iOS 17+, UserDefaults for progress, JSON for questions. No third-party dependencies.

---

## Stage 1: Models & Data Foundation

```
Build Stage 1 of RetroTrivia: the data models and question content.

Create:

1. **TriviaQuestion model** (Models/TriviaQuestion.swift)
   - Struct conforming to Codable
   - Properties: id (String), question (String), options ([String], exactly 4), correctIndex (Int 0-3)
   - Optional: category (String), difficulty (String)

2. **GameState** (Models/GameState.swift)
   - ObservableObject
   - Properties: currentPosition (Int), highScorePosition (Int)
   - Persist to UserDefaults on change (currentPosition, highScorePosition)
   - Methods: incrementPosition(), decrementPosition() (floor at 0), resetGame()
   - Load/save in init and when values change

3. **questions.json** (Data/questions.json)
   - Array of trivia questions about 80's music (1980-1989)
   - Include 25-30 questions: artists (Madonna, Michael Jackson, Prince, Duran Duran, Whitney Houston, etc.), songs, lyrics, release years
   - Valid JSON with id, question, options, correctIndex

4. **Question loader**
   - Add a static method or extension on TriviaQuestion to load from Bundle: `TriviaQuestion.loadFromBundle()` returning [TriviaQuestion]
   - Handle missing file gracefully

Do not build UI yet. Ensure the project compiles and questions load. Add the JSON file to the app target so it's bundled.
```

---

## Stage 2: Retro Theme & Design System

```
Build Stage 2 of RetroTrivia: the visual theme and reusable components.

Prerequisites: Stage 1 complete (TriviaQuestion, GameState, questions.json exist).

Create:

1. **Color assets** (Assets.xcassets)
   - NeonPink: #FF10F0
   - ElectricBlue: #00D4FF
   - HotMagenta: #FF00AA
   - RetroPurple: #2D1B4E (dark background)
   - NeonYellow: #FFFF00
   - Use Color Set with "Any Appearance" and "Dark"

2. **RetroButton** (Components/RetroButton.swift)
   - Reusable SwiftUI button with 80s styling
   - Props: title, action, variant (primary/secondary)
   - Primary: neon pink/cyan gradient border, dark fill, bold text
   - Secondary: outlined style
   - Include subtle scale animation on press

3. **RetroTypography**
   - Define a View extension or constants for:
     - Title: .largeTitle, .bold, neon accent
     - Body: readable, good contrast
   - Use SF Pro Rounded or system font with heavy weight for headings

4. **RetroGradientBackground**
   - A reusable view: dark purple-to-black gradient, optional subtle grid or noise overlay
   - Use as base for screens

Verify: Add a simple preview or temporary view that shows RetroButton and the color palette. No navigation yet.
```

---

## Stage 3: Home Screen

```
Build Stage 3 of RetroTrivia: the home screen.

Prerequisites: Stages 1-2 complete (models, theme, RetroButton, colors).

Create:

1. **HomeView** (Views/HomeView.swift)
   - Full-screen retro-styled layout
   - App title: "RetroTrivia" or "80's Music Trivia" — bold, neon-styled
   - Subtitle or tagline about 80s music
   - Primary "Play" button using RetroButton — starts the game
   - Optional: high score display (from GameState)
   - Use RetroGradientBackground as base
   - Centered, vertically stacked content

2. **ContentView** (update existing)
   - Replace the template List/NavigationView with HomeView
   - Inject GameState as @StateObject: GameState()
   - Pass GameState to HomeView via environment or binding so Play can trigger navigation

3. **Navigation setup**
   - Add @State in ContentView: showGameMap: Bool = false
   - HomeView "Play" sets showGameMap = true
   - When showGameMap: show GameMapView (create a placeholder for now: empty view with "Map" text and a Back button that sets showGameMap = false)
   - Use NavigationStack or fullScreenCover

Deliverable: Tapping Play navigates to a placeholder GameMapView. Back returns to HomeView.
```

---

## Stage 4: Trivia Gameplay View (Core)

```
Build Stage 4 of RetroTrivia: the trivia question screen.

Prerequisites: Stages 1-3 complete. GameMapView is a placeholder.

Create:

1. **TriviaGameView** (Views/TriviaGameView.swift)
   - Props: question (TriviaQuestion), onAnswer: (Bool) -> Void
   - Layout:
     - Question text at top (large, readable, wrapped)
     - 4 answer buttons in 2x2 grid (2 columns)
     - Use RetroButton or similar styling for each option
   - On tap: call onAnswer(true) if correct, onAnswer(false) if wrong
   - Disable all buttons immediately after first tap
   - No haptics or celebrations yet — just functional feedback (e.g., change button color to green/red)

2. **GameMapView** (replace placeholder)
   - For now: simple layout with "Play Trivia" button
   - On tap: pick a random question from TriviaQuestion.loadFromBundle(), present TriviaGameView (sheet or fullScreenCover)
   - Pass GameState: on correct, call gameState.incrementPosition(); on wrong, gameState.decrementPosition()
   - After onAnswer, dismiss the trivia sheet and return to map
   - Include a Back button to return to HomeView

3. **ContentView flow**
   - Ensure GameMapView receives GameState (environment or init)
   - ContentView shows HomeView or GameMapView based on showGameMap

Deliverable: From map, tap Play → see a random trivia question → tap answer → see correct/wrong state → dismiss → map updates position. Full gameplay loop works without polish.
```

---

## Stage 5: Haptic Feedback

```
Build Stage 5 of RetroTrivia: add haptic feedback.

Prerequisites: Stage 4 complete (TriviaGameView, answer handling).

Add SwiftUI sensoryFeedback to TriviaGameView:

1. **Correct answer**: .sensoryFeedback(.success, trigger: isCorrect) when isCorrect is true
   - Or use .impact(weight: .heavy, intensity: 1.0) for a satisfying thud

2. **Wrong answer**: .sensoryFeedback(.warning, trigger: hasAnswered) when the selected answer was wrong
   - Or .impact(weight: .medium, intensity: 0.7)

3. **Button tap**: .sensoryFeedback(.impact(weight: .light), trigger: tappedOption) on each answer button tap
   - Use a trigger that changes when user taps (e.g., selectedOptionId)

Ensure haptics fire at the right moment: correct = success, wrong = warning, tap = light impact. Test on device (simulator has limited haptic support).
```

---

## Stage 6: Celebrations & Negative Feedback Overlays

```
Build Stage 6 of RetroTrivia: celebration and wrong-answer overlays.

Prerequisites: Stage 5 complete. TriviaGameView shows correct/wrong state.

Create:

1. **CelebrationOverlay** (Views/CelebrationOverlay.swift)
   - Full-screen overlay (ignores safe area)
   - Confetti: 50-80 particles falling from top, neon colors (pink, cyan, yellow)
   - Use TimelineView + Canvas or a simple ForEach of shapes with .offset(y) animation
   - "CORRECT!" text, large, glowing, centered
   - Auto-dismiss after 1.5 seconds or animate out
   - Accept onComplete: () -> Void callback

2. **WrongAnswerOverlay** (Views/WrongAnswerOverlay.swift)
   - Semi-transparent dark overlay
   - "WRONG" or "Nope!" text in red/amber
   - Shake animation on the wrong-answer button (use .offset(x) with repeated values for shake)
   - Dim or red-tint the selected wrong button
   - Auto-dismiss after 1.5 seconds
   - Accept onComplete: () -> Void

3. **Integrate into TriviaGameView**
   - Add @State showCelebration = false, showWrong = false
   - On correct: set showCelebration = true, play haptic
   - On wrong: set showWrong = true, apply shake to tapped button, play haptic
   - In onComplete: dismiss overlay, then call onAnswer and dismiss the trivia sheet (with slight delay so user sees feedback)
   - Use ZStack to overlay on top of question/answers

Deliverable: Correct answer shows confetti + "CORRECT!"; wrong answer shows shake + "WRONG". Both dismiss after ~1.5s then return to map.
```

---

## Stage 7: Candy Crush-Style Progress Map

```
Build Stage 7 of RetroTrivia: the vertical progress map.

Prerequisites: Stages 1-6 complete. GameMapView currently has a simple "Play Trivia" button.

Create:

1. **MapNodeView** (Views/MapNodeView.swift)
   - Represents one step on the map
   - Props: levelIndex (Int), isCurrentPosition (Bool)
   - Circle or hexagon shape
   - Show level number or music icon (SF Symbol: music.note)
   - Current position: highlighted (neon glow, larger scale)
   - Past positions: dimmed or checkmark
   - Future positions: outlined, muted

2. **GameMapView** (replace current implementation)
   - Vertical ScrollView with ScrollViewReader
   - LazyVStack of MapNodeView for positions 0..<50 (or more)
   - Player token: the node at gameState.currentPosition is "current"
   - Connect nodes with a path (vertical line or zigzag) between them
   - Use scrollPosition(id:) or scrollTo to keep current position in view when it changes
   - "Play" button or tap on current node to start trivia
   - When returning from trivia: animate scroll to new position (withAnimation)
   - Back button to HomeView

3. **Map layout**
   - Start at bottom (position 0) or top — pick one and be consistent
   - Correct = move up (increase index), wrong = move down (decrease, floor 0)
   - Path: simple vertical line with nodes, or Candy Crush-style winding path with alternating left/right nodes

4. **Retro styling**
   - Neon grid or gradient background
   - Cassette or vinyl icon for nodes
   - Glow effect on current node

Deliverable: Vertical map shows progress. Player token moves up/down correctly. Tapping Play starts trivia; returning updates position and scrolls map. Back button works.
```

---

## Stage 8: Integration & Polish

```
Build Stage 8 of RetroTrivia: wire everything together and polish.

Prerequisites: Stages 1-7 complete.

Tasks:

1. **Navigation flow**
   - HomeView: Play → GameMapView
   - GameMapView: Play/current node → TriviaGameView (sheet)
   - TriviaGameView: answer → overlay → onComplete → dismiss → back to map
   - GameMapView: Back → HomeView
   - Ensure GameState is shared and persisted correctly

2. **Persistence**
   - GameState saves to UserDefaults on position change
   - Persist on app background: add .onChange(of: scenePhase) in app or ContentView to save when going to background
   - Load saved state on launch

3. **Edge cases**
   - Empty questions: handle gracefully
   - Position 0: wrong answer doesn't go negative
   - High score: update when currentPosition > highScorePosition

4. **Polish**
   - Smooth animations when map position changes
   - Consistent retro styling across all screens
   - Remove or repurpose ContentView's Core Data usage (Item) — remove from UI if not needed
   - Ensure no template code (List, Add Item) remains

5. **Optional**
   - Add 20+ more questions to questions.json
   - Milestone celebration at every 5th correct answer
   - App icon with 80s cassette/vinyl motif

Deliverable: Complete, playable game. Progress persists. All flows work. Ready for TestFlight or App Store.
```

---

## Quick Reference: Stage Checklist

| Stage | Deliverable |
|-------|-------------|
| 1 | TriviaQuestion, GameState, questions.json, loader |
| 2 | Colors, RetroButton, typography, gradient background |
| 3 | HomeView, Play → placeholder GameMapView |
| 4 | TriviaGameView, 4-option grid, answer handling, map integration |
| 5 | Haptic feedback on answer |
| 6 | Confetti overlay (correct), shake overlay (wrong) |
| 7 | Vertical game map with nodes, scroll, player token |
| 8 | Full integration, persistence, polish |

---

## Tips for Using These Prompts

1. **Run one stage at a time** — don't skip ahead.
2. **Verify each stage** before moving on (e.g., "Does it compile? Does the flow work?").
3. **If something breaks** — go back to the last working stage and re-run.
4. **Customize** — add your own questions, tweak colors, change copy.
5. **Reference the plan** — see `.cursor/plans/retrotrivia_80s_music_app_*.plan.md` for full architecture.
