# Vivre Card 🏴‍☠️

**Find Your Nakama** — A real-time friend location compass inspired by One Piece's Vivre Cards.

## Concept

In One Piece, a Vivre Card is a piece of paper that always points toward the person it belongs to, and burns away as that person's life force fades. This app brings that concept to life:

- **Compass Mode**: Select a friend and the Vivre Card rotates to point in their direction
- **Burn Effect**: The closer your friend is, the smaller the card fragment becomes (inverting the anime logic — close = small piece because you're *almost there*)
- **Real-Time**: Location updates stream via Firebase every 3 seconds

---

## Architecture

```
VivreCard/
├── App/
│   ├── VivreCardApp.swift          # Entry point + Firebase init
│   └── RootView.swift              # Auth state router
├── Models/
│   └── Models.swift                # VivreUser, FriendRequest, LiveFriend, Crew
├── Services/
│   ├── LocationService.swift       # CoreLocation GPS + compass heading
│   └── FirebaseService.swift       # Auth, Firestore CRUD, real-time listeners
├── ViewModels/
│   ├── AuthViewModel.swift         # Login/register state
│   └── CompassViewModel.swift      # Bearing calculation + arrow rotation
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift         # Login + Registration
│   ├── Main/
│   │   ├── MainTabView.swift       # Tab navigation (Friends / Compass / Profile)
│   │   ├── FriendListView.swift    # Crew list with live status
│   │   ├── CompassView.swift       # ★ Core vivre card compass
│   │   └── ProfileView.swift       # Pirate profile + settings
│   └── Components/
│       ├── SplashScreenView.swift  # Animated loading screen
│       ├── AddFriendSheet.swift    # Email search + send request
│       └── FriendRequestsSheet.swift
├── Utils/
│   ├── Theme.swift                 # One Piece color palette + typography
│   └── NavigationMath.swift        # Haversine bearing + distance math
└── Resources/
    └── GoogleService-Info.plist    # (You add this from Firebase Console)
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI |
| Auth | Firebase Authentication (Email/Password) |
| Database | Cloud Firestore (real-time listeners) |
| Location | CoreLocation (GPS + magnetometer heading) |
| Math | Haversine formula for bearing, circular mean for heading smoothing |

---

## Rubric Coverage (110 Points)

| Requirement | How It's Met | Points |
|-------------|-------------|--------|
| Project Proposal | This README + concept doc | 10 |
| Source Code | Full SwiftUI project | 10 |
| 3 Screens | Friends List, Compass, Profile | 10 |
| 3 Colors | Straw Hat Red, Grand Line Navy, Parchment (+ Gold, Teal, Orange accents) | 10 |
| 3 Data Types | String, Double, Bool (+ Int, Date, Array) | 10 |
| 3 GUI Objects | List/ScrollView, Custom Compass View, Buttons, Sheets, TextFields, Tab Bar | 10 |
| Web API | Firebase Firestore REST API with real-time listeners | 10 |
| Persistent Storage | Firestore (server), UserDefaults option for local prefs | 10 |
| User Experience | Smooth compass animation, One Piece theming, intuitive flow | 10 |
| Usefulness | Real-time friend finding with directional compass | 10 |

**Beyond the rubric:**
- Pirate Bounty gamification system
- Crew (group) support
- Animated vivre card burn effect
- Heading smoothing with circular mean to prevent jitter
- Friend request system with real-time notifications
- Background location support

---

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called "VivreCard"
3. Add an iOS app with your bundle ID (e.g. `com.yourname.VivreCard`)
4. Download `GoogleService-Info.plist` → drag into Xcode project root

### 2. Enable Services
- **Authentication** → Sign-in method → Enable **Email/Password**
- **Cloud Firestore** → Create database → Start in **test mode**

### 3. Firestore Security Rules (Production)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own document
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Friend requests
    match /friendRequests/{requestId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.toUserID
                    || request.auth.uid == resource.data.fromUserID;
    }
    
    // Crews
    match /crews/{crewId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid in resource.data.memberIDs
                    || request.auth.uid == resource.data.captainID;
    }
  }
}
```

### 4. Xcode Dependencies (Swift Package Manager)
Add Firebase SDK: `https://github.com/firebase/firebase-ios-sdk`
- FirebaseAuth
- FirebaseFirestore

### 5. Info.plist Keys
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Vivre Card needs your location to point your nakama in the right direction.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Background location keeps your Vivre Card active so friends can find you.</string>
```

### 6. Background Modes (Xcode Capabilities)
- ✅ Location updates

---

## How It Works

### Compass Math
The core navigation uses the **Haversine bearing formula**:

1. Get user's GPS coordinate from `CoreLocation`
2. Get friend's GPS coordinate from Firestore (real-time listener)
3. Calculate **absolute bearing** (angle from true north to friend)
4. Subtract **device heading** (which way the phone is pointing)
5. Result = **relative angle** → rotate the vivre card arrow by this amount

The heading is smoothed using a **circular mean** over the last 5 readings to prevent jittery movement around the 0°/360° boundary.

### Vivre Card Burn Effect
Distance maps to card size:
- **0m** → Card is 15% size (tiny fragment — you're right there!)
- **50km+** → Card is 100% size (full card — long journey ahead)

---

## Running the Project

1. Clone/download the project
2. Open in Xcode 15+
3. Add Firebase SDK via SPM
4. Drop in your `GoogleService-Info.plist`
5. Set your team & bundle ID
6. Build & run on a physical device (compass requires real hardware)

> **Note**: The magnetometer (compass) does not work in the iOS Simulator. Use a physical device for testing the compass feature.

---

## Future Ideas
- **Push Notifications** when a friend comes within a certain radius ("Your nakama is nearby!")
- **Map View** toggle to see all friends on a real map
- **SOS Beacon** — tap to alert all friends of your location (emergency vivre card burn)
- **Crew Chat** — simple messaging within a crew
- **Widget** — iOS home screen widget showing nearest friend direction
- **Apple Watch** — vivre card compass on your wrist
