# Audio Files

## Current Background Music

**Track:** "Afterglow Love"
**Artist:** e s c p
**Website:** https://www.escp.space
**Bandcamp:** https://escp-music.bandcamp.com

## Background Music

To add or change background music in RetroTrivia:

1. **Find or create an 80s-style music track**
   - Use royalty-free music from sites like:
     - [Incompetech](https://incompetech.com/) (Kevin MacLeod)
     - [Free Music Archive](https://freemusicarchive.org/)
     - [YouTube Audio Library](https://www.youtube.com/audiolibrary)
   - Search for: "80s synthwave", "retro", "arcade", or "chiptune"

2. **Add the file to the project**
   - Name it: `background-music.mp3`
   - In Xcode: Right-click the `Audio` folder → Add Files to "RetroTrivia"
   - Make sure "Copy items if needed" is checked
   - Ensure "RetroTrivia" target is selected

3. **Recommended music style**
   - 80s synthwave or retro arcade style
   - Upbeat tempo (120-140 BPM)
   - Loopable (no harsh start/end)
   - Not too busy (should not distract from gameplay)

4. **File format**
   - MP3 (most compatible)
   - AAC (.m4a) also works
   - Keep file size reasonable (< 5MB)

## Sound Effects (Optional)

You can also add sound effects:
- `correct-answer.mp3` - Play on correct answer
- `wrong-answer.mp3` - Play on wrong answer
- `button-tap.mp3` - Play on button press

The app will work without these files - they're optional enhancements.

## Music Controls

Players can toggle music on/off in-game (feature can be added to settings).
Volume is set to 50% by default and can be adjusted in AudioManager.
