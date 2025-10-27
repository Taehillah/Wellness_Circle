# Wellness Circle Cloud Functions

This Cloud Functions bundle forwards new circle alerts to Firebase Cloud Messaging. Deploy it with:

```bash
cd firebase/functions
npm install
firebase deploy --only functions:onCircleAlertCreated
```

The trigger listens to `circles/{circleId}/alerts/{alertId}` documents, loads every member in the same circle, fetches their registered `fcmTokens`, and sends a push notification (excluding the sender).

Tokens are registered by the mobile app in `users/{uid}/fcmTokens/{token}` with the associated `circleId` and `memberId` metadata.
