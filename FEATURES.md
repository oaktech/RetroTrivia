# RetroTrivia — Feature Ideas

---

## 📋 Active Task List

### Completed
- [x] Fix: Game timer starts only after Play Trivia click
- [x] Fix: Settings button unresponsive after quitting game
- [x] Feature: Standardize leaderboard to 2-minute timed games
- [x] Feature: Add Play vs Practice mode selection
- [x] Feature: Implement Lives System + Game Center Leaderboard
- [x] Feature: Add app icon to home screen
- [x] Feature: Add scrolling 80s phrases to home screen
- [x] Feature: Fix question timer at 10 seconds
- [x] Feature: Dim/blur questions screen during answer animations

### Pending
- [ ] Feature: Display leaderboard in-app
- [ ] Feature: Expand offline question database
- [ ] Refactor: Implement MVVM architecture
- [ ] Feature: Build question API service and database

---

## 🔥 High Impact / Retention

**Daily Challenge**
A new question set every day with a streak counter. Streaks are one of the strongest retention mechanics (see Duolingo).

**Leaderboard**
GameKit/Game Center integration — global and friends-only rankings. Competitive players share apps.

**Achievements & Badges**
"Answer 10 in a row", "80s Expert", "Night Owl" (played after midnight). Drives long-term engagement.

**Lives System**
Give players 3 lives per run. Wrong answers cost a life — adds stakes and encourages replays.

---

## 🎮 Gameplay Depth

**Timed Mode**
A countdown per question (10-15 sec). Adds pressure and replayability.

**Decade Selector**
Expand beyond 80s — let players choose 70s, 90s, 00s. Widens the audience significantly.

**Category Deep Dives**
Filter by genre (Rock, Pop, Hip-Hop, R&B) or artist. Niche audiences are passionate.

**Multiplayer Pass-and-Play**
Two players, same device, taking turns. Zero infrastructure needed, huge party appeal.

### Pass & Play — Design Spec

**Core concept**: 2–4 players take turns on one device. Each player has their own marker on the shared map. Winner is whoever reaches the highest position when the round ends (or first to the summit).

**Setup screen** (before the game)
- Player count: 2, 3, or 4
- Optional per-player name entry (defaults to "Player 1" etc.)
- Difficulty picker (same as Gauntlet)
- Round limit: 5 / 10 / 15 questions per player, or "Race to 25"

**Turn flow**
1. Full-screen handoff prompt — "Pass to [Player Name]" — so previous player looks away
2. Player answers question (same 10-second per-question timer)
3. Correct → advance marker; Wrong → fall back (no lives — map position is the penalty)
4. Celebration / wrong-answer overlay fires as normal
5. "Pass to [Next Player]" — repeat

**End conditions**
- Fixed rounds: after each player completes their N questions, show final standings
- Race to 25: first player to reach the summit wins instantly

**Map display**: each player gets a distinct colored dot (NeonPink / ElectricBlue / NeonYellow / HotMagenta). If tied at same node, dots stack. Map scrolls to the active player's position at the start of their turn.

**Data model**
- New `PassAndPlaySession` struct — player array, current player index, per-player position
- Purely in-memory (never persists to UserDefaults)
- No leaderboard submission, no badge progress

**Navigation**
```
HomeView → Pass & Play setup sheet
         → PassAndPlayMapView (new)
         → TriviaGameView (reused unchanged)
         → Handoff screen (between turns, tap-to-continue)
         → FinalStandingsView (end of game)
```

**What's reused vs new**
| Component | Status |
|---|---|
| TriviaGameView | Reused unchanged |
| MapNodeView | Reused, extended to show multiple player dots |
| GameState | Not used — replaced by PassAndPlaySession |
| QuestionManager | Reused |
| GameMapView | New PassAndPlayMapView (same map, different header/logic) |
| Handoff screen | New (un-skippable full-screen prompt) |
| Setup screen | New |
| Final standings | New |

**Hint System**
"50/50" or "Skip" consumables — classic trivia mechanic players expect.

---

## 📱 Social / Viral

**Share Your Score**
One-tap share card (image) showing position on the map + score. Free marketing.

**Challenge a Friend**
Send a specific question set to a friend via link and compare scores.

---

## 💰 Monetization (non-intrusive)

**Question Packs**
"Disco Pack", "Hair Metal Pack", "One-Hit Wonders Pack" as one-time IAP.

**Cosmetic Themes**
Alternate map skins (cassette tape theme, vinyl record theme) — no pay-to-win.

---

## 🎨 UI / Design Improvements

### Typography
- **Arcade fonts**: Replace `.fontDesign(.rounded)` system font with [Press Start 2P](https://fonts.google.com/specimen/Press+Start+2P) for titles/headings and [Orbitron](https://fonts.google.com/specimen/Orbitron) for scores/timers. Keep system rounded for readable body text (answers, settings). VT323 as an option for secondary/terminal-style text.

### Screen Transitions
- **Home → Game**: Horizontal scanline wipe (top-to-bottom, like a CRT powering on) instead of default slide-up
- **Wrong answer**: Brief red flash (`Color.red.opacity(0.3)`, ~80ms) before the overlay appears
- **Correct answer**: Quick white flash + scale burst on the answer card before confetti fires
- **Level Up**: Screen shake (offset ±4pt, 3 cycles) before the overlay settles in
- **Game Over**: Fade to black first, then the overlay — more dramatic

### Home Screen
- **Slot-machine phrase transition**: New phrase slides up, old phrase slides up and out (instead of crossfade)
- **Title boot sequence**: Letters type in one by one with cursor blink on first appear, then glow fades in
- **Animated grid**: Slow parallax movement on the background grid (translate ±10pt on a 20s loop) to make the world feel alive
- **Grid opacity**: Increase from 0.15 to 0.25–0.30 — currently barely visible

### Answer Buttons
- **Left-border accent bar**: 4pt neon color bar, invisible until tap — gives each button an edge
- **Isolated shake on wrong**: Shake only the tapped button, not the whole game view
- **Correct answer glow sweep**: Border briefly animates to full NeonYellow glow sweeping left-to-right (200ms) before overlay
- **Keyboard-style letter labels**: A/B/C/D chips on the left side of each answer button — arcade quiz energy

### Timer
- **Sync vignette to ticks**: Urgency vignette pulse should sync with each second countdown tick, not its own interval
- **Accelerating arc**: Timer circle arc trim should speed up as time runs out, not stay linear
- **Tick sound**: Add tick sound in the last 5 seconds (sound effect infra already exists)

### Background & Atmosphere
- **Scanline overlay**: Semi-transparent horizontal band slowly scrolling down (~15s/pass) for CRT authenticity
- **Ambient particle drift**: 10–15 tiny dots (2–3pt) floating upward slowly — cheap to render, big atmosphere boost
- **Richer gradient**: Background bottom stop — deep purple-to-black with a hint of deep blue instead of pure black

### Game Map
- **Node connector lines**: Dashed/pulsing lines between completed → current node to make progression path clearer
- **Completion badge**: Small star/checkmark that pops in on a node when first completed (one-time spring animation)
- **Current node pulse**: After scroll settles, current node does a brief scale pulse (1.0 → 1.1 → 1.0)

### Game Over / Celebration
- **Varied confetti fall speeds**: 3 distinct speed groups (fast/medium/slow) instead of uniform fall
- **Score count-up**: Final score counts up from 0 on overlay appear (classic arcade trick, makes any score feel earned)
- **Rank flash**: Brief Game Center rank display ("YOU RANKED #247 GLOBALLY!") for 1.5s before the full overlay loads

### Buttons (Global)
- **Glow flare on release**: Border briefly brightens to white for 100ms on release — "juicy" press feedback
- **Primary button fill**: Primary variant should have solid NeonPink background fill to better distinguish from secondary

### Quick Wins Summary
| Change | Effort | Impact |
|--------|--------|--------|
| Orbitron font for score/timer | Low | High |
| Score count-up on game over | Low | High |
| Grid opacity 0.25 | Trivial | Medium |
| Letter labels (A/B/C/D) on answer buttons | Low | High |
| Tick sound in last 5 seconds | Low | High |
| White glow flare on button release | Low | Medium |
| Slot-machine phrase transition | Medium | High |
| Scanline overlay | Medium | High |

---

## ✨ Polish

**App Icon on Home Screen**
Display the app icon prominently on the HomeView to add visual polish and brand recognition.

**Scrolling 80s Phrases**
Animated marquee or rotating display of 80s catchphrases ("Totally Tubular!", "Radical!", "Gnarly!") on the home screen to enhance the retro aesthetic.

**Animated Map Characters**
A small retro avatar that walks up/down the map instead of just highlighting a circle.

**Music Snippets**
Play a 5-second clip and identify the song. Needs licensing but would be the killer feature.

**Onboarding Tutorial**
First-run walkthrough of the map mechanics — reduces drop-off.

---

## Priority Notes

**Quick wins** (low effort, high value): Daily Challenge, Share Score, Timed Mode, Lives System.

**Big swings** (high effort, massive differentiation): Music Snippets, Multiplayer, Leaderboard.
