# 🅿️ Omer (P1) — Reporter Journey
**Branch:** `feature/spot-reporting`

---

## Your Job in One Sentence
Build everything that lets a user **report a free parking spot** — take a photo, pin the location, let the AI confirm it's free, and save it to the database.

---

## Setup (do this once)

```bash
# 1. Clone the repo
git clone https://github.com/omerdonovich1/parking-hunters-.git
cd parking-hunters-

# 2. Get dependencies
flutter pub get

# 3. Switch to your branch
git checkout feature/spot-reporting

# 4. Add the Firebase config files (ask Sharon for these — never commit them)
# → ios/Runner/GoogleService-Info.plist
# → android/app/google-services.json

# 5. Run the app
flutter run
```

---

## Files You Will Work On

| File | What to build |
|------|--------------|
| `lib/features/report/presentation/report_screen.dart` | Main report screen UI |
| `lib/services/firestore_service.dart` | Save spot to Firestore |
| `lib/services/storage_service.dart` | Upload photo to Firebase Storage |
| `lib/providers/report_provider.dart` | State management for reporting flow |
| `lib/models/parking_spot_model.dart` | Add any missing fields |

**Do NOT touch these files** (Person 2 owns them):
- `lib/features/map/presentation/map_screen.dart`
- `lib/providers/map_provider.dart`

---

## What You Need to Build

### Step 1 — Report Screen UI
The screen opens when the user taps the orange hunter button on the map.

It should have:
- [ ] Full-screen camera view (use `image_picker` package — already in pubspec)
- [ ] A "Take Photo" button
- [ ] After photo is taken → show preview + confirm/retake buttons
- [ ] A "Pin My Location" button (use `geolocator` — already in pubspec)
- [ ] A "Submit Report" button
- [ ] Loading state while uploading

### Step 2 — Upload Photo
When user submits:
- [ ] Upload the photo to Firebase Storage at path: `spots/{userId}/{timestamp}.jpg`
- [ ] Get back the download URL
- [ ] Use `storage_service.dart` for this logic

### Step 3 — AI Scan
After photo is uploaded, call Claude AI to confirm the spot is free:
- [ ] Send the photo URL to `/api/scan-spot` (endpoint to be added — ask Sharon)
- [ ] AI returns: `{ "is_free": true/false, "confidence": 85, "reason": "No car visible" }`
- [ ] Show the result to the user before saving

### Step 4 — Save to Firestore
Save the confirmed spot to Firestore collection `parking_spots`:
```
parking_spots/{spotId} {
  id: string,
  latitude: double,
  longitude: double,
  photoUrl: string,
  reportedBy: string (userId),
  reportedAt: Timestamp,
  expiresAt: Timestamp (reportedAt + 30 minutes),
  isActive: true,
  confidence: int (0-100),
  aiVerified: bool
}
```

### Step 5 — "Spot Taken" Button
- [ ] Add a button in the spot detail sheet (bottom sheet on map) that marks spot as taken
- [ ] Updates Firestore: `isActive: false`, adds `takenAt: Timestamp`

---

## Firestore Structure Reference

```
parking_spots/          ← main collection
  {spotId}/
    latitude: 32.0853
    longitude: 34.7818
    photoUrl: "https://..."
    reportedBy: "userId123"
    reportedAt: Timestamp
    expiresAt: Timestamp    ← reportedAt + 30 min
    isActive: true
    confidence: 87
    aiVerified: true
    takenAt: null           ← set when someone marks it taken
```

---

## Daily Git Workflow

```bash
# Start of day — pull latest
git checkout feature/spot-reporting
git pull origin feature/spot-reporting

# When you finish something, commit it
git add .
git commit -m "Add camera capture to report screen"
git push origin feature/spot-reporting

# When fully done — open a Pull Request on GitHub
# Go to: https://github.com/omerdonovich1/parking-hunters-
# Click "Compare & pull request" on your branch
```

---

## Questions?
Ask in the group chat or tag @sharondonovich on the GitHub Pull Request.
