# Wellness Circle Cloud Functions

Cloud Functions used by the Wellness Circle app to push FCM notifications when a circle member raises an emergency alert.

## What it does
- Listens to Firestore at `circles/{circleId}/alerts/{alertId}`.
- When a new alert is created, it looks up all users in the same circle, collects their registered FCM tokens from `users/{uid}/fcmTokens/{token}`, excludes the sender, and sends a push notification to the rest of the circle.

## Prerequisites
- Node.js 18 (see `package.json` engines)
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project with Firestore and Cloud Messaging enabled

## Local development with emulators
In one terminal:
```bash
cd firebase/functions
npm install
firebase emulators:start --only functions,firestore
```

Run the app with emulators enabled so alerts are written to the local Firestore instance:
```bash
cd ../../wellcheck
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

When you trigger an alert from the app, the function will log to the emulator console and attempt to deliver a push to any tokens stored under the test users.

## Deploying to production
```bash
cd firebase/functions
npm install
firebase deploy --only functions:onCircleAlertCreated
```

## Notes
- Ensure the mobile app registers FCM tokens under `users/{uid}/fcmTokens/{token}` for each authenticated user.
- Consider adding retry/cleanup for invalid tokens if you begin to see many `messaging/invalid-registration-token` errors in logs.
