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
