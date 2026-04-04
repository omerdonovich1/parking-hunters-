# 🗺️ Yarin (P2) — Explorer Journey
**Branch:** `feature/live-map`

---

## Your Job in One Sentence
Make the map **show real parking spots in real time** — read from the database, display them as markers, handle expiry, and let users interact with each spot.

---

## Setup (do this once)

```bash
# 1. Clone the repo
git clone https://github.com/omerdonovich1/parking-hunters-.git
cd parking-hunters-

# 2. Get dependencies
flutter pub get

# 3. Switch to your branch
git checkout feature/live-map

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
| `lib/features/map/presentation/map_screen.dart` | Connect map to real Firestore data |
| `lib/providers/map_provider.dart` | Stream real spots from Firestore |
| `lib/services/firestore_service.dart` | Add `watchActiveSpots()` stream method |
| `lib/features/map/presentation/widgets/spot_bottom_sheet.dart` | Spot detail UI with photo + AI result |

**Do NOT touch these files** (Person 1 owns them):
- `lib/features/report/presentation/report_screen.dart`
- `lib/services/storage_service.dart`

---

## What You Need to Build

### Step 1 — Stream Spots from Firestore
In `firestore_service.dart`, add a method that watches active spots in real time:
```dart
Stream<List<ParkingSpotModel>> watchActiveSpots() {
  return FirebaseFirestore.instance
    .collection('parking_spots')
    .where('isActive', isEqualTo: true)
    .where('expiresAt', isGreaterThan: Timestamp.now())
    .snapshots()
    .map((snap) => snap.docs
        .map((d) => ParkingSpotModel.fromMap(d.data(), d.id))
        .toList());
}
```

### Step 2 — Riverpod Provider for Spots
In `map_provider.dart`, replace the dummy spots list with a real stream:
- [ ] `StreamProvider<List<ParkingSpotModel>>` that calls `watchActiveSpots()`
- [ ] Remove the hardcoded dummy spots

### Step 3 — Markers on the Map
In `map_screen.dart`:
- [ ] Watch the spots stream provider
- [ ] Render a marker for each active spot
- [ ] Marker color = green if confidence > 70%, yellow if 40-70%, red if < 40%
- [ ] Tapping a marker → opens the spot bottom sheet

### Step 4 — Spot Expiry on the Map
- [ ] Spots with `expiresAt` in the past should NOT show (Firestore query handles this)
- [ ] Add a countdown timer on the marker or bottom sheet: "Expires in 12 min"

### Step 5 — Spot Bottom Sheet
When user taps a spot marker, show a bottom sheet with:
- [ ] Photo of the spot (use `cached_network_image` — already in pubspec)
- [ ] AI confidence badge (e.g. "87% Free")
- [ ] Time reported + countdown to expiry
- [ ] "This spot is taken" button → calls `markSpotTaken(spotId)` in Firestore
- [ ] Reporter's display name

### Step 6 — "Spot Taken" Action
In `firestore_service.dart`:
```dart
Future<void> markSpotTaken(String spotId) {
  return FirebaseFirestore.instance
    .collection('parking_spots')
    .doc(spotId)
    .update({ 'isActive': false, 'takenAt': Timestamp.now() });
}
```

---

## Firestore Structure (written by Person 1)

```
parking_spots/
  {spotId}/
    latitude: 32.0853
    longitude: 34.7818
    photoUrl: "https://..."
    reportedBy: "userId123"
    reportedAt: Timestamp
    expiresAt: Timestamp    ← show countdown from this
    isActive: true          ← filter by this
    confidence: 87          ← use for marker color
    aiVerified: true
    takenAt: null
```

---

## While Waiting for Person 1
Person 1 is building the reporting flow. While they finish, you can:
1. Build the bottom sheet UI with hardcoded mock data
2. Build the stream provider with dummy Firestore data you create manually in the Firebase console
3. Go to [console.firebase.google.com](https://console.firebase.google.com) → Firestore → Add a document manually to `parking_spots` to test your map

**Manual test document to add in Firebase console:**
```
Collection: parking_spots
Document ID: (auto)
Fields:
  latitude: 32.0853 (number)
  longitude: 34.7818 (number)
  photoUrl: "" (string)
  reportedBy: "test" (string)
  reportedAt: (timestamp — now)
  expiresAt: (timestamp — 30 min from now)
  isActive: true (boolean)
  confidence: 85 (number)
  aiVerified: true (boolean)
```

---

## Daily Git Workflow

```bash
# Start of day — pull latest
git checkout feature/live-map
git pull origin feature/live-map

# When you finish something, commit it
git add .
git commit -m "Add real-time spot stream from Firestore"
git push origin feature/live-map

# When fully done — open a Pull Request on GitHub
# Go to: https://github.com/omerdonovich1/parking-hunters-
# Click "Compare & pull request" on your branch
```

---

## Questions?
Ask in the group chat or tag @sharondonovich on the GitHub Pull Request.
