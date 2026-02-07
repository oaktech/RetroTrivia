# Sound Effects Implementation Plan - RetroTrivia

## Overview
Add comprehensive sound effects throughout the RetroTrivia app to complement existing haptic feedback and create an immersive 80s arcade gaming experience.

## Current State
- ✅ AudioManager exists with background music support
- ✅ `playSoundEffect(named:withExtension:)` method available
- ✅ Haptic feedback implemented at key interaction points
- ✅ AudioManager injected via environment from RetroTriviaApp
- ❌ No sound effect files or integration
- ❌ No sound effects toggle or volume control

## Implementation Strategy

### Phase 1: AudioManager Enhancement
**File:** `RetroTrivia/Audio/AudioManager.swift`

Add sound effects controls:
- `isSoundEffectsEnabled: Bool` property (persisted to UserDefaults)
- `soundEffectsVolume: Float` property (persisted to UserDefaults, default 0.8)
- Update `playSoundEffect()` to respect toggle and volume settings
- Update `init()` to load sound effects preferences

**Lines to modify:**
- Add properties after `musicVolume` (around line 22)
- Update `init()` to load preferences (around line 36)
- Update `playSoundEffect()` to check toggle (around line 71)

### Phase 2: Core Gameplay Sounds (High Priority)

#### 2A: TriviaGameView - Answer Interactions
**File:** `RetroTrivia/Views/TriviaGameView.swift`

Add sounds for:
- Button tap when selecting answer → `button-tap.mp3`
- Correct answer immediate feedback → `correct-answer.mp3`
- Wrong answer immediate feedback → `wrong-answer.mp3`

**Changes:**
- Add `@Environment(AudioManager.self) var audioManager` property (line ~10)
- In `handleAnswer()` method (line ~104):
  - Play `button-tap.mp3` before `buttonTapTrigger += 1`
  - Play `correct-answer.mp3` before `correctAnswerTrigger.toggle()`
  - Play `wrong-answer.mp3` before `wrongAnswerTrigger.toggle()`
- Update preview to inject AudioManager.shared

#### 2B: CelebrationOverlay - Victory Sound
**File:** `RetroTrivia/Views/CelebrationOverlay.swift`

Add celebration sound (1.5s duration to match overlay):
- Celebration fanfare → `celebration.mp3`

**Changes:**
- Add `@Environment(AudioManager.self) var audioManager` property
- In `.onAppear` (line ~48): Play `celebration.mp3` before animation
- Update preview to inject AudioManager.shared

#### 2C: WrongAnswerOverlay - Buzzer Sound
**File:** `RetroTrivia/Views/WrongAnswerOverlay.swift`

Add wrong buzzer sound (1.5s duration to match overlay):
- Wrong answer buzzer → `wrong-buzzer.mp3`

**Changes:**
- Add `@Environment(AudioManager.self) var audioManager` property
- In `.onAppear` (line ~43): Play `wrong-buzzer.mp3` before animation
- Update preview to inject AudioManager.shared

**Sound Files Needed (Phase 2):**
- `button-tap.mp3` (100-200ms)
- `correct-answer.mp3` (300ms)
- `celebration.mp3` (1500ms - full celebratory sound)
- `wrong-answer.mp3` (300ms)
- `wrong-buzzer.mp3` (1500ms - buzzer/descending tone)

### Phase 3: Navigation Sounds (Medium Priority)

#### 3A: GameMapView - Play Button
**File:** `RetroTrivia/Views/GameMapView.swift`

Add sounds for:
- Play/Next Question button → `question-start.mp3`
- Back button → `back-button.mp3`
- Position advancement → `node-unlock.mp3`

**Changes:**
- Add `@Environment(AudioManager.self) var audioManager` property (line ~10)
- In `startTrivia()` (line ~160): Play `question-start.mp3` at start
- In `header` back button (line ~95): Play `back-button.mp3` in action
- In `handleAnswer()` (line ~177): Play `node-unlock.mp3` when correct (incrementPosition)

#### 3B: HomeView - UI Sounds
**File:** `RetroTrivia/Views/HomeView.swift`

Add sounds for:
- Music toggle → `music-toggle.mp3`
- Play button → reuse `question-start.mp3`

**Changes:**
- AudioManager already injected as environment (line 10)
- In music toggle button action (line ~21): Play `music-toggle.mp3` before toggle
- In Play button (line ~63): Play `question-start.mp3` before onPlayTapped()

**Sound Files Needed (Phase 3):**
- `question-start.mp3` (400ms)
- `back-button.mp3` (200ms)
- `music-toggle.mp3` (200ms)
- `node-unlock.mp3` (500ms)

### Phase 4: Sound File Acquisition & Setup

**Sound file sources:**
- Freesound.org - search "arcade button", "correct ding", "wrong buzzer"
- Zapsplat.com - free tier with attribution
- Mixkit.co - royalty-free sound effects
- AI generation tools (ElevenLabs Sound Effects)
- GarageBand/Audacity for custom creation

**File specifications:**
- Format: MP3
- Sample rate: 44.1kHz
- Bit rate: 128kbps
- Durations: Buttons 100-300ms, Feedback 300-800ms, Overlays 1500ms

**Installation:**
1. Create/acquire 9 sound effect MP3 files (listed above)
2. In Xcode: Right-click `Audio` folder → Add Files to "RetroTrivia"
3. Check "Copy items if needed"
4. Select "RetroTrivia" target
5. Files should appear under `RetroTrivia/Audio/` in Project Navigator

**Complete file checklist:**
- [ ] button-tap.mp3
- [ ] correct-answer.mp3
- [ ] celebration.mp3
- [ ] wrong-answer.mp3
- [ ] wrong-buzzer.mp3
- [ ] question-start.mp3
- [ ] back-button.mp3
- [ ] music-toggle.mp3
- [ ] node-unlock.mp3

## Critical Files to Modify

1. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Audio/AudioManager.swift`
   - Add sound effects toggle and volume control

2. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Views/TriviaGameView.swift`
   - Highest impact - answer button sounds and immediate feedback

3. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Views/CelebrationOverlay.swift`
   - Celebration sound matching 1.5s overlay duration

4. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Views/WrongAnswerOverlay.swift`
   - Wrong buzzer sound matching 1.5s overlay duration

5. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Views/GameMapView.swift`
   - Navigation sounds for buttons and progression

6. `/Users/oaktech/src/RetroTrivia/RetroTrivia/Views/HomeView.swift`
   - UI sounds for music toggle and play button

## Sound + Haptic Coordination Pattern

All sounds should be played immediately before their corresponding haptic trigger:

```swift
// Pattern: Sound first, then haptic
audioManager.playSoundEffect(named: "button-tap")
buttonTapTrigger += 1 // Haptic fires after sound starts
```

This creates tight, synchronized feedback.

## Implementation Order

**Recommended sequence:**

1. **Phase 1** - AudioManager enhancement (foundation)
2. **Phase 4** - Acquire 3 test sounds (button-tap, correct-answer, wrong-answer)
3. **Phase 2A** - TriviaGameView answer buttons (test with 3 sounds)
4. **Verify** - Test core gameplay sounds work
5. **Phase 4** - Add remaining 6 sound files
6. **Phase 2B-C** - Overlay sounds
7. **Phase 3** - Navigation sounds
8. **Final test** - Complete end-to-end testing

**Time estimate:** 3-4 hours (including sound file acquisition)

## Verification

### Build Test
```bash
cd /Users/oaktech/src/RetroTrivia
xcodebuild -scheme RetroTrivia -destination 'platform=iOS Simulator,name=iPhone 17' build
```

### Manual Testing Checklist

**Sound Effects Toggle:**
- [ ] Toggle sound effects off → no sounds play
- [ ] Toggle sound effects on → sounds resume
- [ ] Preferences persist after app restart
- [ ] Sound effects independent of music toggle

**Gameplay Sounds:**
- [ ] Answer button tap plays button-tap.mp3
- [ ] Correct answer plays correct-answer.mp3 → celebration.mp3 on overlay
- [ ] Wrong answer plays wrong-answer.mp3 → wrong-buzzer.mp3 on overlay
- [ ] Sounds sync with haptic feedback (no delay)

**Navigation Sounds:**
- [ ] Play/Next Question button plays question-start.mp3
- [ ] Back button plays back-button.mp3
- [ ] Music toggle plays music-toggle.mp3
- [ ] Position advancement plays node-unlock.mp3

**Edge Cases:**
- [ ] Missing sound files fail gracefully (console warning only)
- [ ] Rapid button tapping doesn't cause crashes
- [ ] Sounds respect iOS mute switch

## Graceful Degradation

**Missing sound files:** App functions perfectly
- `playSoundEffect()` has guard that returns early if file not found
- Console warning logged for debugging
- No user-facing error
- Haptic feedback still works

**Sound effects disabled:** Full functionality maintained
- Visual feedback unchanged
- Haptic feedback unchanged
- Music continues independently

## Notes

- Single AVAudioPlayer approach is sufficient (sounds don't need to overlap much)
- Overlay sounds (celebration.mp3, wrong-buzzer.mp3) are 1.5s to match auto-dismiss timing
- Layered effect: immediate feedback sound + overlay sound creates compound audio experience
- All sound effects coordinate with existing haptic feedback
- No changes needed to RetroButton component (sounds added at call sites for better context)
