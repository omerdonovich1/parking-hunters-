# 🏆 Omer Gal (P3) — Competitor Journey
**Branch:** `feature/profile-gamification`

---

## Your Job in One Sentence
Build everything that makes users **want to keep coming back** — profile screen, XP bar, badges, and a leaderboard.

---

## Setup (do this once)

```bash
# 1. Clone the repo
git clone https://github.com/omerdonovich1/parking-hunters-.git
cd parking-hunters-

# 2. Get dependencies
flutter pub get

# 3. Switch to your branch
git checkout feature/profile-gamification

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
| `lib/features/profile/presentation/profile_screen.dart` | Avatar, XP bar, level, stats, badges grid |
| `lib/features/leaderboard/presentation/leaderboard_screen.dart` | Top hunters list, weekly ranking |
| `lib/providers/profile_provider.dart` | User profile state, XP updates |
| `lib/services/firestore_service.dart` | `getLeaderboard()`, `getUserProfile()` |
| `lib/models/app_user_model.dart` | User model with points, level, badgeIds |

**Do NOT touch these files** (owned by other people):
- `lib/features/report/` — Omer (P1)
- `lib/features/map/` — Yarin (P2)

---

## What You Need to Build

### Step 1 — User Profile Screen
File: `lib/features/profile/presentation/profile_screen.dart`

- [ ] Show avatar (use first letter of name if no photo)
- [ ] Username + email
- [ ] Current level (1–5) with label: Rookie / Hunter / Pro / Expert / Legend
- [ ] XP bar showing progress to next level
- [ ] Stats row: Total spots reported | Confirmed by others | Days active
- [ ] Badges grid (earned = color, not earned = grey + locked icon)

**Level thresholds:**
```
Level 1 — Rookie     0–49 pts
Level 2 — Hunter     50–149 pts
Level 3 — Pro        150–299 pts
Level 4 — Expert     300–499 pts
Level 5 — Legend     500+ pts
```

### Step 2 — Badges
File: `lib/models/badge_model.dart` (create if missing)

Badges to implement:
| Badge ID | Name | How to earn |
|---|---|---|
| `first_hunt` | First Hunt | Report your first spot |
| `speed_demon` | Speed Demon | Report a spot within 1 min of parking |
| `gold_hunter` | Gold Hunter | Reach 100 points |
| `night_owl` | Night Owl | Report a spot after midnight |
| `streak_3` | Streak x3 | Report 3 days in a row |
| `top_10` | Top 10 | Appear in weekly leaderboard top 10 |

### Step 3 — Leaderboard
File: `lib/features/leaderboard/presentation/leaderboard_screen.dart`

- [ ] Fetch top 20 users sorted by `weeklyPoints` from Firestore
- [ ] Show rank number, avatar, name, points
- [ ] Highlight current user's row
- [ ] "This week" / "All time" toggle

Firestore query:
```dart
Future<List<AppUser>> getLeaderboard({bool weekly = true}) {
  final field = weekly ? 'weeklyPoints' : 'totalPoints';
  return FirebaseFirestore.instance
    .collection('users')
    .orderBy(field, descending: true)
    .limit(20)
    .get()
    .then((snap) => snap.docs.map((d) => AppUser.fromMap(d.data())).toList());
}
```

### Step 4 — Points History
On the profile screen, add a recent activity list:
- [ ] "+10 pts — Reported a spot · 2h ago"
- [ ] "+5 pts — Spot confirmed · Yesterday"
- [ ] "+15 pts — First report of the day · Monday"

---

## Firestore Structure (users collection)

```
users/
  {userId}/
    displayName: "Omer Gal"
    email: "omer@..."
    photoUrl: "https://..."
    totalPoints: 120
    weeklyPoints: 45
    totalReports: 12
    level: 3
    badgeIds: ["first_hunt", "gold_hunter"]
    createdAt: Timestamp
```

---

## Points System (already wired up by Sharon)

| Action | Points |
|---|---|
| Report a spot | +10 |
| Your spot confirmed by another user | +5 |
| First report of the day | +15 bonus |

Points are updated automatically when Omer (P1) submits a report. Your job is to **display** them — not calculate them.

---

## Design Guidelines

- Background: `#080B14` (dark navy)
- Accent: `#FF6B35` (orange) for XP bar, level badge
- Earned badges: full color with glow
- Locked badges: `Colors.white12` with lock icon overlay
- Use `BackdropFilter` + `ImageFilter.blur` for glass cards (same style as rest of app)

---

## Daily Git Workflow

```bash
# Start of day — pull latest
git checkout feature/profile-gamification
git pull origin feature/profile-gamification

# When you finish something, commit it
git add .
git commit -m "Add profile screen with XP bar and level"
git push origin feature/profile-gamification

# When fully done — open a Pull Request on GitHub
# Go to: https://github.com/omerdonovich1/parking-hunters-
# Click "Compare & pull request" on your branch
```

---

## Questions?
Ask in the group chat or tag @sharondonovich on the GitHub Pull Request.
