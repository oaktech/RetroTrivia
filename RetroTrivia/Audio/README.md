# Audio Files

## Current Music Tracks

**Menu Music:** "Afterglow Love" by e s c p
- Website: https://www.escp.space
- Bandcamp: https://escp-music.bandcamp.com

**Gameplay Music:** "Retro" by jiglr
- SoundCloud: https://soundcloud.com/jiglrmusic
- Music promoted by: https://www.free-stock-music.com
- License: CC BY 3.0
- https://creativecommons.org/licenses/by/3.0/deed.en_US

## Background Music

RetroTrivia uses **two different music tracks**:
- **Menu Music**: Plays on the home screen
- **Gameplay Music**: Plays during the game map and trivia questions

### Required Music Files

You need to add two MP3 files to this Audio folder:

1. **`menu-music.mp3`** - Background music for the home screen
2. **gameplay-music.mp3`** - Background music for the game map and trivia

### How to Add Background Music

1. **Find or create 80s-style music tracks**
   - Use royalty-free music from sites like:
     - [Incompetech](https://incompetech.com/) (Kevin MacLeod)
     - [Free Music Archive](https://freemusicarchive.org/)
     - [YouTube Audio Library](https://www.youtube.com/audiolibrary)
   - Search for: "80s synthwave", "retro", "arcade", or "chiptune"

2. **Add the files to the project**
   - Name them exactly: `menu-music.mp3` and `gameplay-music.mp3`
   - In Xcode: Right-click the `Audio` folder → Add Files to "RetroTrivia"
   - Make sure "Copy items if needed" is checked
   - Ensure "RetroTrivia" target is selected

3. **Recommended music style**
   - 80s synthwave or retro arcade style
   - Upbeat tempo (120-140 BPM)
   - Loopable (no harsh start/end)
   - Not too busy (should not distract from gameplay)
   - Menu music can be slightly mellower than gameplay music

4. **File format**
   - MP3 (most compatible)
   - AAC (.m4a) also works
   - Keep file size reasonable (< 5MB per track)

## Sound Effects (Optional)

You can also add sound effects:
- `correct-answer.mp3` - Play on correct answer
- `wrong-answer.mp3` - Play on wrong answer
- `button-tap.mp3` - Play on button press

The app will work without these files - they're optional enhancements.

## Music Controls

Players can toggle music on/off in-game (feature can be added to settings).
Volume is set to 50% by default and can be adjusted in AudioManager.
