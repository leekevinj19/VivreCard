# Vivre Card 🏴‍☠️

A real-time friend location app inspired by One Piece. Point your phone and it'll show you exactly which direction your friends are and how far away they are — like a real Vivre Card.

---

## What it does

- **Compass** — points toward a friend in real time using your phone's GPS and compass
- **Friend System** — add friends by email, accept or decline requests
- **Live Status** — see which friends are online and when they were last active
- **Profile** — every user has a pirate name, crew, and bounty that grows over time

---

## How to run it

1. Clone the repo
2. Open `VivreCard.xcodeproj` in Xcode
3. Add the Firebase SDK via Swift Package Manager: `https://github.com/firebase/firebase-ios-sdk`
4. Get a `GoogleService-Info.plist` from [Firebase Console](https://console.firebase.google.com) and drop it into the project
5. Build and run on a real device (the compass doesn't work in the simulator)

---

## Tech used

- **SwiftUI** — all the UI
- **Firebase Auth** — login and accounts
- **Firebase Firestore** — stores users, friends, and live locations
- **CoreLocation** — GPS and compass heading

---

## Notes

- `GoogleService-Info.plist` is not included for security reasons — you'll need your own Firebase project to run it
- The compass works best on a physical device
- Background location is enabled so your position updates even when the app isn't open
