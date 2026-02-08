# Files to Add to Xcode Project

The following new files have been created but need to be added to the Xcode project:

## New Files Created

### Services (create new group if it doesn't exist)
- `Services/TriviaAPIService.swift` - API client for Open Trivia Database
- `Services/QuestionManager.swift` - Question pool manager with session tracking

### Models
- `Models/FilterConfiguration.swift` - User preferences for difficulty and online mode

### Views
- `Views/SettingsView.swift` - Settings UI for configuring question filters

## How to Add Files to Xcode

1. Open the RetroTrivia project in Xcode
2. In the Project Navigator, right-click on the appropriate group (Services, Models, or Views)
3. Select "Add Files to RetroTrivia..."
4. Navigate to the file location
5. Make sure "Copy items if needed" is **unchecked** (files are already in place)
6. Make sure "Add to targets: RetroTrivia" is **checked**
7. Click "Add"

Repeat for each file.

## Or Use This Shortcut

1. Open the RetroTrivia project in Xcode
2. Drag and drop all the files from Finder into their respective groups in Xcode
3. In the dialog, uncheck "Copy items if needed" and ensure RetroTrivia target is selected
4. Click "Finish"

## Files Already Modified (no action needed)
- `Models/TriviaQuestion.swift` - Added QuestionSource enum and custom initializer
- `Views/GameMapView.swift` - Updated to use QuestionManager
- `Views/HomeView.swift` - Added settings button
- `RetroTriviaApp.swift` - Injected QuestionManager into environment

## Verification

After adding the files, build the project (Cmd+B) to verify there are no errors.
