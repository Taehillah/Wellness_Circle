const functions = require('firebase-functions');
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const messaging = admin.messaging();

exports.onCircleAlertCreated = functions.firestore
  .document('circles/{circleId}/alerts/{alertId}')
  .onCreate(async (snapshot, context) => {
    const alert = snapshot.data();
    if (!alert) {
      return null;
    }

    const circleId = context.params.circleId;
    const senderId = alert.senderId;
    const message = alert.message || 'Emergency alert';
    const locationText = alert.locationText || '';

    const usersSnapshot = await db
      .collection('users')
      .where('circleId', '==', circleId)
      .get();

    const tokens = [];
    for (const userDoc of usersSnapshot.docs) {
      const data = userDoc.data();
      const legacyId = data.legacyId;
      if (legacyId && senderId && Number(legacyId) === Number(senderId)) {
        continue;
      }
      const tokenSnapshot = await userDoc.ref.collection('fcmTokens').get();
      for (const tokenDoc of tokenSnapshot.docs) {
        const tokenData = tokenDoc.data();
        if (tokenData && tokenData.token) {
          tokens.push(tokenData.token);
        }
      }
    }

    if (!tokens.length) {
      functions.logger.info('No FCM tokens found for circle', circleId);
      return null;
    }

    const notification = {
      title: alert.senderName || 'Circle member needs help',
      body: locationText ? `${message}\n${locationText}` : message,
    };

    const payload = {
      notification,
      data: {
        circleId,
        alertId: context.params.alertId,
        senderId: senderId ? String(senderId) : '',
        locationText,
      },
    };

    try {
      const response = await messaging.sendEachForMulticast({
        tokens,
        notification,
        data: payload.data,
      });
      functions.logger.info('Sent emergency alert notification', response);
    } catch (error) {
      functions.logger.error('Failed to send alert notification', error);
    }

    return null;
  });
