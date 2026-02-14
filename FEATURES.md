# RetroTrivia — Feature Ideas

---

## 🔥 High Impact / Retention

**Daily Challenge**
A new question set every day with a streak counter. Streaks are one of the strongest retention mechanics (see Duolingo).

**Hint System**
"50/50" or "Skip" consumables — classic trivia mechanic players expect.

---

## 🎮 Gameplay Depth

**Decade Selector**
Expand beyond 80s — let players choose 70s, 90s, 00s. Widens the audience significantly.

**Category Deep Dives**
Filter by genre (Rock, Pop, Hip-Hop, R&B) or artist. Niche audiences are passionate.

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

### Quick Wins Summary
| Change | Effort | Impact | Status |
|--------|--------|--------|--------|
| Orbitron font for score/timer | Low | High | Done |
| Score count-up on game over | Low | High | Done |
| Grid opacity 0.25 | Trivial | Medium | |
| Letter labels (A/B/C/D) on answer buttons | Low | High | |
| Tick sound in last 5 seconds | Low | High | Done |
| White glow flare on button release | Low | Medium | |
| Slot-machine phrase transition | Medium | High | |
| Scanline overlay | Medium | High | |

---

## ✨ Polish

**Animated Map Characters**
A small retro avatar that walks up/down the map instead of just highlighting a circle.

**Music Snippets**
Play a 5-second clip and identify the song. Needs licensing but would be the killer feature.

**Onboarding Tutorial**
First-run walkthrough of the map mechanics — reduces drop-off.
