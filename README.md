# Parking Hunter 🅿️

A gamified, crowd-sourced parking finder app — like Pokémon Go but for parking spots.
Built with Flutter + Firebase. iOS & Android.

---

## What is it?

Users report free parking spots in real time. The app uses **AI (Claude Vision)** to scan a photo of the spot and confirm it's actually free. Spots expire after 30 minutes unless someone refreshes them. Everyone earns points and badges for reporting.

---

## Core Features

| Feature | Status |
|---------|--------|
| Full-screen dark map (OpenStreetMap) | ✅ Done |
| Premium dark UI / glassmorphism design | ✅ Done |
| Google + Apple + Email sign-in | ✅ Done |
| 4-step spot reporting flow | ✅ Done |
| AI photo scan (Claude Vision) | ✅ Done |
| Upload photo to Firebase Storage | ✅ Done |
| Save spot to Firestore | ✅ Done |
| Real-time spots on map | 🔧 In progress (P2) |
| Spot expiry after 30 min | 🔧 In progress (P2) |
| Profile screen + XP bar | 🔧 In progress (P3) |
| Badges + leaderboard | 🔧 In progress (P3) |

---

## Tech Stack

- **Flutter** — iOS & Android
- **Firebase** — Auth, Firestore, Storage
- **OpenStreetMap** via `flutter_map` — free, no API key needed
- **Claude Vision API** — AI photo scan to verify free spots
- **Riverpod** — state management
- **go_router** — navigation

---

## Team & Branches

| Person | Branch | Responsibility |
|--------|--------|---------------|
| Sharon (P1) | `feature/spot-reporting` | Report flow + AI scan |
| Person 2 | `feature/live-map` | Real-time map from Firestore |
| Person 3 | `feature/profile-gamification` | Profile, points, badges, leaderboard |

Each person has a detailed guide in the `docs/` folder.

---

## How to Run

```bash
git clone https://github.com/omerdonovich1/parking-hunters-.git
cd parking-hunters-
git checkout feature/your-branch
flutter pub get
flutter run
```

Tap **"Try Demo Mode"** on the login screen — no Firebase setup needed to start developing.

---

## Spot Reporting Flow

1. **Pin location** — GPS detects where the spot is
2. **Take photo** — mandatory camera shot of the spot
3. **AI scan** — Claude Vision analyzes the photo and returns:
   - `is_free: true/false`
   - `confidence: 0–100%`
   - `reason: "No car visible in the space"`
4. **Submit** — spot saved to Firestore, expires in 30 min, user earns +10 pts

---

## Spot Lifecycle

```
Reported → Active (30 min) → Expired
                ↓
        Someone marks it taken → Immediately removed
                ↓
        New photo submitted → Timer resets to 30 min
```

---

## Gamification

- **+10 pts** — report a spot
- **+5 pts** — your spot gets confirmed by another user
- **+15 pts** — first report of the day (bonus)
- Levels 1–5 based on total points
- Badges: First Hunt, Speed Demon, Gold Hunter, Night Owl, Streak x3, Top 10

---

## Project Structure

```
lib/
  core/
    config/       # Firebase options, app constants
    theme/        # Dark theme, glassmorphism helpers
    utils/        # Router, constants
    widgets/      # Shared widgets (ad banner, loading, etc.)
  features/
    auth/         # Login screen (Google, Apple, email)
    home/         # Shell + floating bottom nav
    map/          # Full-screen map + spot markers
    report/       # 4-step report flow
    profile/      # User profile + badges
    leaderboard/  # Top hunters
    onboarding/   # First-launch screens
    settings/     # Theme toggle etc.
  models/         # ParkingSpot, AppUser, Report, Badge
  providers/      # Riverpod providers
  services/       # Auth, Firestore, Storage, AI scan, Location
docs/
  PERSON_1_SPOT_REPORTING.md
  PERSON_2_LIVE_MAP.md
  PERSON_3_PROFILE_GAMIFICATION.md
```

---

## Firestore Collections

```
parking_spots/   — active spot reports
users/           — user profiles + points + badges
reports/         — raw report logs
```

---

## Important Notes

- `GoogleService-Info.plist` and `google-services.json` are **gitignored** — never commit them. Ask the team lead for these files when you're ready to test with real Firebase.
- Claude API key lives in `lib/core/config/app_config.dart` — replace `YOUR_CLAUDE_API_KEY` before running on device. Never commit this key.
