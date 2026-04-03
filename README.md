# Parking Hunter 🅿️

A gamified, crowd-sourced parking finder app built with Flutter and Firebase.

## Features

- Real-time parking spot map with confidence scores
- Crowd-sourced reporting with points + badge rewards
- Searcher/Hunter mode toggle
- Leaderboard and weekly league
- Google and Apple Sign-In

---

## Setup Instructions

### 1. Firebase Setup

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project called **parking-hunter**.
2. Add an **Android** app:
   - Package name: `com.example.parking_hunter`
   - Download `google-services.json`
   - Place it at `android/app/google-services.json`
3. Add an **iOS** app:
   - Bundle ID: `com.example.parkingHunter`
   - Download `GoogleService-Info.plist`
   - Place it at `ios/Runner/GoogleService-Info.plist`
4. Enable **Authentication** providers: Email/Password, Google, Apple
5. Enable **Cloud Firestore** in test mode (lock down rules before production)
6. Enable **Firebase Storage**

### 2. Google Maps API Key

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Enable **Maps SDK for Android** and **Maps SDK for iOS**
3. Create an API key and restrict it to your app

**Android** — add to `android/app/src/main/AndroidManifest.xml` inside `<application>`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

**iOS** — add to `ios/Runner/AppDelegate.swift`:
```swift
import GoogleMaps
// In application(_:didFinishLaunchingWithOptions:):
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

Also update `lib/core/config/app_config.dart`:
```dart
static const String googleMapsApiKey = 'YOUR_API_KEY_HERE';
```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

For release builds:
```bash
flutter build apk --release
flutter build ios --release
```

---

## Team Workflow (Multiple Developers)

1. **Never commit** `google-services.json`, `GoogleService-Info.plist`, or `key.properties` — these are gitignored.
2. Each developer sets up their own Firebase config files locally.
3. Use a shared **Notion / Confluence doc** to store non-secret setup steps.
4. For CI/CD: inject Firebase config files via environment secrets in your pipeline (GitHub Actions, Codemagic, etc.).
5. To generate code (freezed, riverpod):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

---

## Project Structure

```
lib/
  core/
    config/       # App constants and config
    theme/        # Material 3 light/dark theme
    utils/        # Router, constants
    widgets/      # Reusable widgets
  features/
    auth/         # Auth screen
    home/         # Shell + bottom nav
    map/          # Google Map + spot bottom sheet
    report/       # 3-step report flow
    profile/      # User profile, badges, league
    gamification/ # League model
  models/         # Parking spot, user, report, badge
  providers/      # Riverpod state providers
  services/       # Auth, Firestore, Location, Gamification
```

---

## Firestore Security Rules (Production)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /parking_spots/{spotId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```
