# Auto-Advance Feature Documentation

## Overview

The auto-advance feature creates a fluid, engaging flow between trivia questions by automatically loading the next question after a brief visual countdown, eliminating the need to repeatedly tap "Next Question."

## User Experience Flow

### Before (Manual)
1. User answers question
2. Overlay appears (celebration/wrong answer)
3. Overlay dismisses → back to map
4. User must tap "Next Question" button
5. Next question loads

### After (Auto-Advance)
1. User answers question
2. Overlay appears (celebration/wrong answer)
3. Overlay dismisses → back to map
4. **Animated progress bar appears** (2.5 seconds)
5. **Next question auto-loads**
6. (Optional) Tap to skip the countdown

## Visual Design

### Dual-Collapse Progress Bar

The progress bar features a unique dual-collapse animation:

```
[========================================] (Start: 100%)
[==============        ==============]
[=====                        =====]
[==                              ==]
[                                  ] (End: 0%)
    ↓
 SNAP → Next Question
```

**Design Details:**
- Two gradient bars collapse toward center from both sides
- Left bar: NeonPink → ElectricBlue gradient
- Right bar: ElectricBlue → HotMagenta gradient
- Background: Subtle white track (10% opacity)
- Height: 6pt with 3pt corner radius
- Duration: 2.5 seconds linear animation

### Text Elements

**"Next question in..."**
- Font: Caption
- Color: White 70% opacity
- Position: Above progress bar

**"Tap to skip"**
- Font: Caption
- Color: NeonYellow
- Appears after 1 second
- Position: Below progress bar

## Technical Implementation

### State Variables

```swift
@State private var showAutoAdvance: Bool = false
@State private var autoAdvanceProgress: CGFloat = 1.0
@State private var canSkipWait: Bool = false
```

### Animation Timeline

| Time | Event |
|------|-------|
| 0.0s | User answers question |
| 0.5s | Auto-advance starts (after overlay dismisses) |
| 1.0s | "Tap to skip" button appears |
| 2.5s | Progress bar reaches 0%, next question loads |
| 2.6s | Next question appears with snap effect |

### Key Functions

**`startAutoAdvance()`**
- Resets progress to 100%
- Shows progress bar UI
- Starts 2.5s animation
- Schedules auto-load at end

**`skipAutoAdvance()`**
- Cancels countdown
- Hides progress bar
- Immediately loads next question

**`loadNextQuestion()`**
- Hides progress UI
- Adds 0.1s snap delay
- Calls `startTrivia()`

## User Controls

### Skip Option
- **Appears:** After 1 second of countdown
- **Action:** Tap "Tap to skip" text
- **Result:** Immediately loads next question

### Automatic Progression
- **Duration:** 2.5 seconds total
- **Visual feedback:** Dual-collapse progress bar
- **Completion:** Smooth snap to next question

## Edge Cases Handled

### 1. No More Questions
- Auto-advance won't start if question pool is empty
- User sees "No questions available" message

### 2. Level-Up Overlay
- Auto-advance waits for level-up overlay to dismiss
- Countdown starts after all overlays clear

### 3. User Leaves During Countdown
- If user quits game during countdown, timers are cancelled
- No questions load in background

### 4. Multiple Rapid Answers
- Each answer resets the countdown
- Previous countdowns are cancelled
- Only latest countdown runs

## Accessibility

### Visual Indicators
- Clear progress bar shows time remaining
- Text label explains what's happening
- Skip option provides user control

### Timing Considerations
- 2.5 seconds is long enough to read and process
- 1 second delay before skip appears prevents accidental taps
- Users can skip if they want faster pace

## Benefits

### User Experience
✅ **Fluid gameplay** - No repetitive button tapping
✅ **Visual feedback** - Clear indication of what's happening
✅ **User control** - Can skip if desired
✅ **Engaging** - Keeps momentum going

### Engagement
✅ **Faster sessions** - Less friction between questions
✅ **Better flow** - Natural rhythm established
✅ **More addictive** - "Just one more question" effect

### Polish
✅ **Modern UX** - Matches contemporary app expectations
✅ **Retro aesthetic** - Neon gradients fit theme
✅ **Smooth animations** - Professional feel

## Configuration Options

Want to adjust the timing? Edit these values in `GameMapView.swift`:

```swift
// In startAutoAdvance()
.asyncAfter(deadline: .now() + 1.0)  // Skip button delay
.linear(duration: 2.5)               // Progress bar duration
.asyncAfter(deadline: .now() + 2.5)  // Auto-load timing

// In handleAnswer()
.asyncAfter(deadline: .now() + 0.5)  // Auto-advance start delay

// In loadNextQuestion()
.asyncAfter(deadline: .now() + 0.1)  // Snap effect delay
```

## Comparison to Other Games

### Trivia Apps
- **HQ Trivia:** Manual next button (slow)
- **Trivia Crack:** Auto-advance after 3s (similar)
- **QuizUp:** Instant next (too fast)
- **RetroTrivia:** 2.5s with skip option (balanced) ✅

### Match-3 Games (Candy Crush style)
- **Candy Crush:** Auto-cascade with brief pauses
- **Bejeweled:** Smooth transitions
- **RetroTrivia:** Similar auto-flow philosophy ✅

## Future Enhancements (Optional)

### Possible Improvements
- [ ] Configurable timing in settings (slow/normal/fast)
- [ ] Sound effect when progress bar completes
- [ ] Particle effects during snap transition
- [ ] Different animation styles per tier
- [ ] Haptic feedback on auto-load
- [ ] Preview of next question difficulty

### Advanced Features
- [ ] Combo counter for consecutive correct answers
- [ ] Speed bonus for quick answers
- [ ] Animation variations based on streak
- [ ] Customizable progress bar style

## Testing Checklist

- [x] Progress bar appears after answering
- [x] Dual-collapse animation runs smoothly
- [x] Next question loads after 2.5 seconds
- [x] "Tap to skip" appears after 1 second
- [x] Skip button works immediately
- [x] Auto-advance cancels when question pool empty
- [x] Level-up overlay doesn't interfere
- [x] Animations don't jank or stutter
- [x] Gradients render correctly
- [x] Text is readable on all devices

## Code Location

**File:** `RetroTrivia/Views/GameMapView.swift`

**Key Sections:**
- Lines ~14-17: State variables
- Lines ~227-280: Progress bar UI (`playButton` view)
- Lines ~320-370: Auto-advance logic

**Total Added:** ~100 lines
**Complexity:** Medium
**Performance Impact:** Minimal (simple animations)

---

**Feature Status:** ✅ Implemented and tested
**Build Status:** ✅ Clean build
**Ready for:** User testing and feedback
