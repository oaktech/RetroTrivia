# CloudKit Setup Guide for RetroTrivia

This guide walks you through enabling CloudKit for the question delivery system.

## Prerequisites

- Apple Developer Account (paid membership required)
- Xcode 15+
- Signed in to iCloud on your development Mac

## Step 1: Enable CloudKit Capability in Xcode

1. Open `RetroTrivia.xcodeproj` in Xcode
2. Select the **RetroTrivia** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** and add **iCloud**
5. Check **CloudKit** under Services
6. Under Containers, click the **+** button
7. Create container: `iCloud.com.oak-tech.RetroTrivia`

> **Note:** The entitlements file has already been updated with the CloudKit configuration. You just need to enable the capability in Xcode and let it regenerate provisioning profiles.

## Step 2: Create CloudKit Schema

### Option A: CloudKit Dashboard (Recommended)

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select your container: `iCloud.com.oak-tech.RetroTrivia`
3. Navigate to **Schema** → **Record Types**
4. Create a new Record Type called `Question`
5. Add these fields:

| Field Name | Type | Description |
|------------|------|-------------|
| `questionText` | String | The question text |
| `options` | List (String) | Array of 4 answer options |
| `correctIndex` | Int(64) | Index of correct answer (0-3) |
| `category` | String | Category (e.g., "Music") |
| `difficulty` | String | "easy", "medium", or "hard" |
| `isActive` | Int(64) | 1 = active, 0 = disabled |
| `sortOrder` | Int(64) | Random 0-9999 for efficient sampling (required for 10K+ questions) |

6. Navigate to **Schema** → **Indexes**
7. Add these indexes:
   - `sortOrder` → Queryable, Sortable (IMPORTANT for large datasets)
   - `difficulty` → Queryable, Sortable
   - `isActive` → Queryable
   - `category` → Queryable
   - `createdAt` → Sortable (auto-created)

8. Navigate to **Schema** → **Security Roles**
9. For the `Question` record type, set:
   - **World**: Read
   - **Authenticated**: Read
   - **Creator**: Read, Write

### Option B: Code-Based Schema (Auto-Generated)

The schema will be automatically created when you first save a record. Just run the migration script and the fields will be created.

## Step 3: Migrate Questions to CloudKit

The migration script is located at: `Scripts/CloudKitMigration.swift`

### Option A: Using Xcode

1. Create a new macOS Command Line Tool target in your project
2. Add CloudKit framework to the target
3. Copy `CloudKitMigration.swift` to the new target
4. Update the `questionsPath` variable to point to `Data/questions_full_backup.json`
5. Run the target

### Option B: Using CloudKit Dashboard

1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Select **Data** → **Records**
3. Click **Create Record**
4. For each question in `Data/questions_full_backup.json`:
   - Set Record Type to `Question`
   - Fill in all fields
   - Click **Save**

### Option C: Using CloudKit JS API

Use the CloudKit JS API to bulk upload from a web interface. See Apple's documentation for details.

## Step 4: Verify Setup

1. Build and run the app on a device or simulator
2. Ensure you're signed in to iCloud on the device
3. Enable "Online Questions" in Settings
4. Questions should load from CloudKit

Check the debug console for messages like:
```
DEBUG: CloudKit - Fetched 25 questions
```

## Fallback Behavior

The question loading follows this priority:

1. **CloudKit** (primary) - Fetches from iCloud public database
2. **Open Trivia DB** (secondary) - Falls back to third-party API
3. **Local Cache** - Uses cached questions if offline
4. **Bundled Fallback** - Uses 20 emergency questions from `questions.json`

## Files Overview

| File | Purpose |
|------|---------|
| `Services/CloudKitQuestionService.swift` | CloudKit fetch logic |
| `Services/QuestionCacheManager.swift` | Local cache for offline support |
| `Extensions/TriviaQuestion+CloudKit.swift` | CKRecord ↔ TriviaQuestion conversion |
| `Services/QuestionManager.swift` | Updated with CloudKit integration |
| `RetroTrivia.entitlements` | CloudKit entitlements |
| `Data/questions.json` | Emergency fallback (20 questions) |
| `Data/questions_full_backup.json` | Full question set for migration |
| `Scripts/CloudKitMigration.swift` | Migration script |

## Troubleshooting

### "Provisioning profile doesn't include iCloud capability"
- Regenerate provisioning profiles in Xcode
- Go to Signing & Capabilities and let Xcode manage signing

### "CloudKit container not found"
- Ensure the container `iCloud.com.oak-tech.RetroTrivia` is created
- Wait a few minutes for the container to propagate

### "No questions loaded"
- Check CloudKit Dashboard for records
- Verify the `isActive` field is set to 1
- Check debug console for error messages

### Questions not showing difficulty filter
- Ensure the `difficulty` field is indexed as Queryable
- Check that difficulty values match: "easy", "medium", "hard" (lowercase)

## Cost Estimate (Free Tier)

| Resource | Free Tier | Expected Usage |
|----------|-----------|----------------|
| Database | 100 MB | ~1 MB (200 questions) |
| Asset Storage | 1 GB | 0 (no assets) |
| Requests | 40/sec, 100K/day | ~1K/day |
| Data Transfer | 250 MB/day | ~10 MB/day |

**Total Cost: $0** (well within free tier)

## Scaling to 10,000+ Questions

The implementation is optimized for large datasets:

### How Random Sampling Works

Instead of fetching all questions and shuffling (which doesn't scale), we use a `sortOrder` field:

1. Each question has a random `sortOrder` value (0-9999)
2. To get random questions, we query a random 10% slice (e.g., sortOrder 3000-4000)
3. Results are shuffled client-side for additional randomness
4. Falls back to standard fetch if sortOrder isn't indexed yet

### Performance at Scale

| Questions | Fetch Time | CloudKit Queries |
|-----------|------------|------------------|
| 200 | ~0.5s | 1 |
| 1,000 | ~0.5s | 1 |
| 10,000 | ~0.5s | 1 |
| 50,000 | ~0.5s | 1 |

The random sampling approach keeps fetch time constant regardless of total question count.

### Storage Estimate

| Questions | Database Size |
|-----------|---------------|
| 200 | ~100 KB |
| 1,000 | ~500 KB |
| 10,000 | ~5 MB |
| 50,000 | ~25 MB |

All within the 100 MB free tier.

### Adding New Questions

When adding questions to an existing database:
1. Assign random `sortOrder` values (0-9999) to new questions
2. Distribution doesn't need to be perfect - random is fine
3. Questions will be sampled proportionally from all sortOrder ranges
