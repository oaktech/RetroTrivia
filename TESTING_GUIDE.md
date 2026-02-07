# API Integration Testing Guide

## Quick Start Test

1. **Open the project in Xcode**
   ```bash
   open /Users/oaktech/src/RetroTrivia/RetroTrivia.xcodeproj
   ```

2. **Build the project** (Cmd+B)
   - Xcode will auto-detect new files
   - Should build successfully

3. **Run on simulator** (Cmd+R)
   - Select any iPhone simulator
   - App should launch normally

## Test Scenarios

### Scenario 1: Online Questions (Happy Path)

**Setup:**
- Ensure WiFi/network is enabled
- Launch app

**Steps:**
1. Tap the gear icon (settings) in HomeView
2. Verify "Online Questions" toggle is ON
3. Set difficulty to "Any"
4. Tap "Close"
5. Tap "Play"
6. Observe console logs:
   ```
   DEBUG: Loading questions (online: true, difficulty: Any)
   DEBUG: Fetching questions from API: ...
   DEBUG: Successfully fetched X questions from API
   DEBUG: Pool: X total, X unanswered, 0 asked
   ```
7. Tap "Play Trivia"
8. Answer question
9. Check question source in console
10. Play 5-10 questions and verify no repeats

**Expected:**
- ✅ Questions load from API
- ✅ No repeated questions
- ✅ Questions display correctly (HTML entities decoded)
- ✅ Progress updates normally

---

### Scenario 2: Difficulty Filtering

**Setup:**
- Network enabled, app running

**Steps:**
1. Open Settings
2. Set difficulty to "Easy"
3. Close settings
4. Tap "Play" (resets session)
5. Tap "Play Trivia"
6. Check console: Questions should be easy difficulty
7. Repeat with "Medium" and "Hard"

**Expected:**
- ✅ API requests include difficulty parameter
- ✅ Questions match selected difficulty
- ✅ Settings persist after app restart

---

### Scenario 3: Offline Fallback

**Setup:**
- Enable airplane mode OR disconnect WiFi

**Steps:**
1. Launch app
2. Open Settings - verify "Online Questions" is ON
3. Close settings
4. Tap "Play"
5. Observe console logs:
   ```
   DEBUG: Loading questions (online: true, difficulty: Any)
   DEBUG: API fetch failed: ..., falling back to bundled questions
   DEBUG: Loaded X bundled questions
   ```
6. Tap "Play Trivia"
7. Verify questions are from bundled set (80s music specific)

**Expected:**
- ✅ No crashes
- ✅ Seamless fallback to bundled questions
- ✅ Game plays normally
- ✅ "Loading questions..." appears briefly

---

### Scenario 4: Bundled Only Mode

**Setup:**
- Network enabled

**Steps:**
1. Open Settings
2. Toggle "Online Questions" OFF
3. Close settings
4. Tap "Play"
5. Console should show:
   ```
   DEBUG: Loaded X bundled questions
   ```
6. Play trivia

**Expected:**
- ✅ Only bundled questions used
- ✅ No API requests made
- ✅ Questions are 80s music themed
- ✅ Difficulty filter still applies

---

### Scenario 5: Session Reset

**Setup:**
- App running with questions loaded

**Steps:**
1. Play 5 questions, noting their content
2. Go back to HomeView (Quit Game)
3. Tap "Play" again
4. Console should show:
   ```
   DEBUG: Session reset - cleared X asked questions
   ```
5. Play trivia
6. Verify you CAN see previously asked questions again

**Expected:**
- ✅ Session resets on "Play" button
- ✅ Previously asked questions can appear again
- ✅ No duplicates within new session

---

### Scenario 6: Auto-Refill

**Setup:**
- Online mode enabled

**Steps:**
1. Set up logging to watch pool size
2. Play 15+ questions continuously
3. Watch console for refill messages:
   ```
   DEBUG: Refilling question pool (current: 9)
   DEBUG: Refilled pool with X new questions (total: Y)
   ```

**Expected:**
- ✅ Pool refills automatically when below 10 questions
- ✅ No interruption in gameplay
- ✅ No duplicate questions added

---

### Scenario 7: HTML Entity Decoding

**Setup:**
- Online mode, play until you see questions with special characters

**Steps:**
1. Look for questions containing:
   - Apostrophes (Who's, It's, etc.)
   - Quotes ("Thriller", etc.)
   - Ampersands (Rock & Roll)
   - Accented characters (Beyoncé)
2. Verify they display correctly, not as &quot; or &#039;

**Expected:**
- ✅ Apostrophes show as ' not &#039;
- ✅ Quotes show as " not &quot;
- ✅ Special characters display correctly

---

### Scenario 8: Rate Limiting

**Setup:**
- Online mode

**Steps:**
1. Force multiple rapid API calls by:
   - Playing game
   - Quitting back to home
   - Tapping "Play" again immediately
   - Repeat 3-4 times quickly
2. Observe console for rate limiting:
   ```
   (May see slight delay between requests)
   ```

**Expected:**
- ✅ No "rate limit exceeded" errors
- ✅ Requests spaced at least 5 seconds apart
- ✅ No crashes

---

## Visual Verification Checklist

### Settings Screen
- [ ] Settings button (gear icon) visible in HomeView header
- [ ] Settings sheet opens smoothly
- [ ] "Online Questions" toggle styled with neon pink
- [ ] Difficulty picker has 4 options (Any/Easy/Medium/Hard)
- [ ] Category shows "Music 🔒"
- [ ] Info text shows current mode
- [ ] Close button works
- [ ] Retro theme consistent with rest of app

### HomeView
- [ ] Settings button doesn't overlap music toggle
- [ ] Both buttons have proper spacing
- [ ] Settings button has haptic feedback

### GameMapView
- [ ] "Loading questions..." shows during API fetch
- [ ] Play button disabled while loading
- [ ] No visual glitches when questions load
- [ ] Gameplay unchanged from before

---

## Console Log Reference

### Successful API Load
```
DEBUG: QuestionManager initialized with 50 bundled questions
DEBUG: Loading questions (online: true, difficulty: Any)
DEBUG: Fetching questions from API: https://opentdb.com/api.php?...
DEBUG: Acquired new session token
DEBUG: Successfully fetched 25 questions from API
DEBUG: Pool: 25 total, 25 unanswered, 0 asked
DEBUG: Selected question: What was Madonna's first hit?
DEBUG: Marked question ABC123 as asked (1 total asked)
```

### Offline Fallback
```
DEBUG: Loading questions (online: true, difficulty: Any)
DEBUG: Fetching questions from API: https://opentdb.com/api.php?...
DEBUG: API fetch failed: Network error: ..., falling back to bundled questions
DEBUG: Loaded 50 bundled questions
DEBUG: Pool: 50 total, 50 unanswered, 0 asked
```

### Bundled Only
```
DEBUG: Loading questions (online: false, difficulty: Any)
DEBUG: Loaded 50 bundled questions
DEBUG: Pool: 50 total, 50 unanswered, 0 asked
```

### Difficulty Filtering
```
DEBUG: Loading questions (online: false, difficulty: Easy)
DEBUG: Loaded 18 bundled questions  // Subset matching difficulty
```

---

## Performance Benchmarks

Expected timing:
- API fetch: 500ms - 2s (first request, includes token)
- API fetch: 200ms - 1s (subsequent requests)
- Bundled load: <100ms
- Question display: Immediate
- Settings open/close: <300ms

---

## Troubleshooting

### "Cannot find QuestionManager in scope"
- **Fix:** Clean build folder (Cmd+Shift+K) and rebuild

### "No questions available"
- **Check:** Network connection
- **Check:** Console for API errors
- **Fix:** Toggle "Online Questions" off to use bundled

### Questions repeat immediately
- **Check:** Session reset is being called
- **Debug:** Add breakpoint in `markQuestionAsked()`
- **Fix:** Verify `questionManager.resetSession()` in HomeView

### Settings don't persist
- **Check:** UserDefaults saving
- **Debug:** Print `filterConfig` after load
- **Fix:** Verify `FilterConfiguration.save()` is called

### App crashes on launch
- **Check:** All files added to Xcode target
- **Fix:** Build Phases → Compile Sources → verify new files listed

---

## Success Criteria

All scenarios pass ✅ when:
1. Online mode fetches from API successfully
2. Offline mode falls back gracefully
3. No repeated questions in single session
4. Difficulty filtering works for API and bundled
5. Settings persist across app restarts
6. HTML entities display correctly
7. UI is polished and matches retro theme
8. No crashes in any scenario
9. Console logs are clean (no errors)
10. Performance is smooth (no lag)

---

## Next Actions After Testing

1. ✅ All tests pass → Ready for commit
2. ❌ Issues found → Debug and fix
3. 📝 Document any quirks or limitations
4. 🎨 Polish UI if needed
5. 📊 Consider analytics/logging for production
