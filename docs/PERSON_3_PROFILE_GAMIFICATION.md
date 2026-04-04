# 🏆 Person 3 — Profile & Gamification
**Branch:** `feature/profile-gamification`

---

## Your Job in One Sentence
Make the app **feel like a game** — build the profile screen, points system, badges, and leaderboard so users are motivated to keep reporting spots.

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
| `lib/features/profile/presentation/profile_screen.dart` | Full profile UI |
| `lib/features/leaderboard/presentation/leaderboard_screen.dart` | Top hunters list |
| `lib/services/gamification_service.dart` | Points + badge logic |
| `lib/providers/profile_provider.dart` | State for user profile |
| `lib/models/user_model.dart` | Add any missing fields |
| `lib/models/badge_model.dart` | Badge definitions |

**Do NOT touch these files:**
- `lib/features/map/` — Person 2 owns this
- `lib/features/report/` — Person 1 owns this

---

## What You Need to Build

### Step 1 — Profile Screen
A full dark-themed profile page that shows:
- [ ] User avatar (initials circle if no photo)
- [ ] Display name + email
- [ ] Current level + XP progress bar (e.g. "Level 3 · 450/500 XP")
- [ ] Total reports count
- [ ] Badges grid (earned badges bright, unearned ones greyed out)
- [ ] Settings button (top right)

### Step 2 — Points & Levels System
In `gamification_service.dart`, implement:
- [ ] Points per action:
  - Report a spot → +10 pts
  - Spot confirmed by another user → +5 pts
  - First report of the day → +15 pts (bonus)
- [ ] Level thresholds:
  ```
  Level 1: 0–99 pts
  Level 2: 100–299 pts
  Level 3: 300–599 pts
  Level 4: 600–999 pts
  Level 5: 1000+ pts
  ```
- [ ] `int getLevel(int points)` — returns current level
- [ ] `double getLevelProgress(int points)` — returns 0.0–1.0 for XP bar

### Step 3 — Badges
Define these badges in `badge_model.dart` and implement unlock logic in `gamification_service.dart`:

| Badge ID | Name | How to earn |
|----------|------|------------|
| `first_hunter` | First Hunt | Submit first report |
| `speed_demon` | Speed Demon | Report 5 spots in one day |
| `gold_hunter` | Gold Hunter | Reach 1000 points |
| `night_owl` | Night Owl | Report a spot after midnight |
| `streak_3` | On a Roll | Report 3 days in a row |
| `top_10` | Top 10 | Reach top 10 on leaderboard |

- [ ] `List<String> checkNewBadges(AppUser user)` — returns list of newly unlocked badge IDs
- [ ] Each badge has: id, name, emoji, description, isSecret (bool)

### Step 4 — Leaderboard Screen
- [ ] Show top 20 users ordered by points
- [ ] Highlight the current user's row
- [ ] Rank badge: 🥇🥈🥉 for top 3, number for the rest
- [ ] Each row: rank + avatar + name + level + points
- [ ] Reads from Firestore `users` collection ordered by `points`

### Step 5 — Level Up Animation
When a user levels up after submitting a report:
- [ ] Show a full-screen overlay with the new level number
- [ ] Orange glow + celebration animation
- [ ] Auto-dismisses after 3 seconds
- [ ] File: `lib/features/home/presentation/widgets/level_up_overlay.dart` (already exists, improve it)

---

## Firestore Structure (users collection)

```
users/
  {userId}/
    id: string
    email: string
    displayName: string
    photoUrl: string (optional)
    points: number        ← increment when they report
    level: number         ← recalculate when points change
    totalReports: number  ← increment on each report
    badgeIds: string[]    ← add badge ID when unlocked
    createdAt: Timestamp
```

---

## Color Guide (match the app's dark theme)

```dart
// From AppTheme:
bg = Color(0xFF080B14)        // background
card = Color(0xFF111827)      // card background
orange = Color(0xFFFF6B35)    // primary / XP bar
neonGreen = Color(0xFF00E676) // success / level up
neonYellow = Color(0xFFFFD600) // gold badges
cardBorder = Color(0xFF1F2937) // borders
```

Use `BackdropFilter` + `ImageFilter.blur` for glass cards (same pattern as auth screen).

---

## Daily Git Workflow

```bash
# Start of day — pull latest
git checkout feature/profile-gamification
git pull origin feature/profile-gamification

# When you finish something, commit it
git add .
git commit -m "Add badge grid to profile screen"
git push origin feature/profile-gamification

# When fully done — open a Pull Request on GitHub
# Go to: https://github.com/omerdonovich1/parking-hunters-
# Click "Compare & pull request" on your branch
```

---

## Questions?
Tag @sharondonovich on the GitHub Pull Request or ask in the group chat.
