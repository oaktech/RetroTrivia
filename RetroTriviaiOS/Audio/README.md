# Audio Files

## Overview

RetroTrivia features a comprehensive audio system with:
- **Background Music** - Two different tracks for menu and gameplay
- **Sound Effects** - 8 different sound effects for user interactions
- **Volume Controls** - Separate controls for music and sound effects
- **Persistence** - User preferences saved across app sessions

All audio is managed by `AudioManager.swift`, an @Observable singleton that handles playback, looping, and user preferences.

---

## Background Music

### Current Music Tracks

**Menu Music:** "Afterglow Love" by e s c p
- File: `menu-music.mp3` (8.3 MB)
- Plays on: Home screen
- Website: https://www.escp.space
- Bandcamp: https://escp-music.bandcamp.com
- License: Check with artist for commercial use

**Gameplay Music:** "Retro" by jiglr
- File: `gameplay-music.mp3` (8.3 MB)
- Plays on: Game map, trivia questions, overlays
- SoundCloud: https://soundcloud.com/jiglrmusic
- Music promoted by: https://www.free-stock-music.com
- License: CC BY 3.0 (https://creativecommons.org/licenses/by/3.0/deed.en_US)

### Music Behavior

- **Loops indefinitely** - Both tracks loop seamlessly
- **Automatic switching** - Changes between menu and gameplay tracks
- **Volume**: Default 50% (configurable via AudioManager)
- **Toggle**: Music can be toggled on/off via speaker icon in HomeView
- **Persistence**: Music preference saved to UserDefaults
- **Background resilience**: Pauses when app backgrounds, resumes on foreground

---

## Sound Effects

All sound effects are fully implemented and play during gameplay:

### 1. Button Tap (`button-tap.mp3`, 32 KB)
**Plays when:**
- Tapping "Play" button
- Tapping "Next Question" button
- Tapping settings options
- Any primary button interaction

**Volume:** 80% (default sound effects volume)

### 2. Celebration (`celebration.mp3`, 33 KB)
**Plays when:**
- User answers a question correctly
- Celebration overlay appears
- Position increases on the map

**Volume:** 80%

### 3. Wrong Answer (`wrong-answer.wav`, 336 KB)
**Plays when:**
- User answers a question incorrectly
- Wrong answer overlay appears
- Position decreases on the map

**Volume:** 80%

**Note:** Also includes `wrong-buzzer.mp3` (60 KB) as an alternative

### 4. Question Start (`question-start.mp3`, 56 KB)
**Plays when:**
- Trivia question screen appears
- New question is presented

**Volume:** 80%

### 5. Music Toggle (`music-toggle.mp3`, 15 KB)
**Plays when:**
- User taps the speaker icon to toggle music on/off

**Volume:** 80%

### 6. Back Button (`back-button.mp3`, 3.0 KB)
**Plays when:**
- User taps "Quit Game" button
- Navigating back from game to menu

**Volume:** 80%

### 7. Node Unlock (`node-unlock.wav`, 516 KB)
**Plays when:**
- Player reaches a new position on the map
- Visual map node animation triggers
- Intensity increases with tier progression

**Volume:** 80%

---

## Audio Manager Features

### Volume Controls

```swift
// Music
var musicVolume: Float = 0.5 // 50% default
var isMusicEnabled: Bool = true

// Sound Effects
var soundEffectsVolume: Float = 0.8 // 80% default
var isSoundEffectsEnabled: Bool = true
```

### Persistent Settings

All audio preferences are saved to UserDefaults:
- Music enabled/disabled state
- Music volume level
- Sound effects enabled/disabled state
- Sound effects volume level

### Audio Session

- **Category:** `.ambient` - Allows background audio from other apps
- **Mode:** `.default` - Standard playback mode
- **Auto-activated** - Audio session starts on app launch

### Playback Methods

```swift
// Background Music
playMenuMusic()                    // Start menu track
playGameplayMusic()                // Start gameplay track
stopBackgroundMusic()              // Stop current track
pauseBackgroundMusic()             // Pause (preserves position)
resumeBackgroundMusic()            // Resume from pause

// Sound Effects
playSoundEffect(named: "button-tap")                    // MP3 default
playSoundEffect(named: "wrong-answer", withExtension: "wav")  // Custom extension
playSoundEffect(named: "celebration", volume: 1.0)      // Custom volume
```

---

## File Format Requirements

### Background Music
- **Format:** MP3 (preferred) or M4A
- **Size:** < 10 MB recommended (current: ~8 MB each)
- **Duration:** Any length (will loop)
- **Sample Rate:** 44.1 kHz recommended
- **Bitrate:** 128-320 kbps
- **Channels:** Stereo
- **Looping:** Should have seamless loop points (no harsh start/end)

### Sound Effects
- **Format:** MP3 or WAV
- **Size:** < 1 MB recommended
- **Duration:** 0.5 - 3 seconds (short and punchy)
- **Sample Rate:** 44.1 kHz or 48 kHz
- **Bitrate:** 128-192 kbps for MP3
- **Channels:** Stereo or Mono

---

## How to Replace Audio Files

### Replace Background Music

1. Find royalty-free or licensed 80s-style music
2. Convert to MP3 format
3. Name exactly: `menu-music.mp3` or `gameplay-music.mp3`
4. In Xcode:
   - Right-click `Audio` folder
   - Select "Add Files to RetroTrivia..."
   - Choose "Copy items if needed"
   - Select "RetroTrivia" target
   - Replace when prompted

### Replace Sound Effects

Same process as music:
1. Find or create sound effect
2. Convert to MP3 or WAV
3. Name exactly as the file you're replacing
4. Add to Xcode project (replace existing)

---

## Recommended Music Sources

### Free/Royalty-Free Music
- **Incompetech** (https://incompetech.com/) - Kevin MacLeod's collection
- **Free Music Archive** (https://freemusicarchive.org/)
- **YouTube Audio Library** (https://www.youtube.com/audiolibrary)
- **Pixabay Music** (https://pixabay.com/music/)
- **Bensound** (https://www.bensound.com/)

### Search Terms
- "80s synthwave"
- "retro arcade"
- "chiptune"
- "synthpop"
- "outrun"
- "vaporwave"

### Recommended Style
- **Tempo:** 120-140 BPM for gameplay, 90-110 BPM for menu
- **Style:** Synthwave, retrowave, or arcade-inspired
- **Mood:** Upbeat and energetic (not too intense)
- **Loopable:** Clean loop points for seamless playback

---

## Sound Effects Sources

### Free Sound Effects
- **Freesound** (https://freesound.org/)
- **Zapsplat** (https://www.zapsplat.com/)
- **SoundBible** (https://soundbible.com/)
- **99Sounds** (https://99sounds.org/)

### Effect Characteristics
- **Button Tap:** Short click/beep (< 0.5s)
- **Celebration:** Uplifting chime/fanfare (1-2s)
- **Wrong Answer:** Descending tone/buzzer (1-2s)
- **Question Start:** Attention-grabbing chirp (0.5s)
- **Music Toggle:** Subtle click (< 0.3s)
- **Back Button:** Soft whoosh/click (< 0.5s)
- **Node Unlock:** Rising tone/shimmer (0.5-1s)

---

## Audio Implementation Details

### Where Audio Is Used

**HomeView:**
- Menu music starts
- Music toggle button (speaker icon)
- Button tap sounds

**GameMapView:**
- Gameplay music starts
- Button tap sounds
- Back button sound
- Node unlock sounds (on position change)

**TriviaGameView:**
- Question start sound
- Button tap sounds

**CelebrationOverlay:**
- Celebration sound
- Haptic feedback (separate from audio)

**WrongAnswerOverlay:**
- Wrong answer sound
- Haptic feedback (separate from audio)

**LevelUpOverlay:**
- Enhanced celebration sound
- Visual + audio fanfare

---

## Troubleshooting

### Music Not Playing
- Check music toggle (speaker icon in HomeView)
- Verify file names exactly match: `menu-music.mp3`, `gameplay-music.mp3`
- Check Xcode target membership (file must be in RetroTrivia target)
- Check console for "Music file not found" errors

### Sound Effects Not Playing
- Check `isSoundEffectsEnabled` setting
- Verify file extensions match the code (mp3 vs wav)
- Check console for "Sound effect NOT FOUND" errors
- Verify files are in Xcode project target

### Volume Issues
- Check `musicVolume` (default: 0.5)
- Check `soundEffectsVolume` (default: 0.8)
- Verify device volume is up
- Check silent mode switch on device

---

## License Compliance

**Current Audio Assets:**

✅ **menu-music.mp3** - "Afterglow Love" by e s c p
- License: Check with artist for distribution
- Credit required: Yes

✅ **gameplay-music.mp3** - "Retro" by jiglr
- License: CC BY 3.0
- Credit required: Yes (provided)
- Commercial use: Allowed with attribution

⚠️ **Sound Effects**
- Verify licensing for each effect
- Keep attribution if required
- Replace with original/licensed effects for commercial release

**For Commercial Release:**
- Verify all audio licenses allow commercial use
- Provide required attribution
- Consider commissioning original music/effects
- Consult with legal advisor for license compliance

---

## Future Enhancements

Potential audio improvements:
- [ ] Volume sliders in settings
- [ ] Individual sound effect toggles
- [ ] More music track options
- [ ] Dynamic music based on game tier
- [ ] Fade in/out transitions between tracks
- [ ] Spatial audio for sound effects
- [ ] Accessibility: Visual indicators for audio cues

---

## Technical Details

**AudioManager.swift** (4.1 KB)
- Singleton pattern (`AudioManager.shared`)
- @Observable for SwiftUI integration
- AVFoundation-based playback
- UserDefaults for persistence
- Separate players for music and effects
- Smart track switching (no restart if already playing)

**Total Audio Size:** ~18 MB (mostly background music)

**Supported Formats:**
- MP3 (primary)
- WAV (for high-quality effects)
- M4A (alternative for music)

---

**Last Updated:** 2026-02-07
**API Integration:** Complete
**Audio System:** Fully Implemented
