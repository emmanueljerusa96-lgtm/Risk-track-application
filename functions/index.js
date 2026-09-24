'use strict';

const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { logger } = require('firebase-functions');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { reviewMessage } = require('./messages');

initializeApp();
const db = getFirestore();

async function notify(uid, reportId, eventId, message) {
  const ref = db.collection('users').doc(uid).collection('notifications')
    .doc(`${reportId}_${eventId}`);
  try {
    // Stable event ID avoids duplicate in-app notifications on trigger retries.
    await ref.create({
      reportId, kind: message.kind, title: message.title, body: message.body,
      read: false, createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    if (error.code === 6 || error.code === 'already-exists') return;
    throw error;
  }

  const devices = await db.collection('users').doc(uid).collection('devices')
    .limit(100).get();
  const valid = devices.docs.filter((doc) =>
    typeof doc.data().token === 'string' && doc.data().token.length > 20);
  if (valid.length === 0) return;
  // FCM permits up to 500 tokens per multicast; device reads above are capped.
  const result = await getMessaging().sendEachForMulticast({
    tokens: valid.map((doc) => doc.data().token),
    notification: { title: message.title, body: message.body },
    data: { reportId, kind: message.kind },
  });
  await Promise.all(result.responses.map(async (response, i) => {
    const code = response.error?.code;
    if (code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token') {
      await valid[i].ref.delete();
    }
  }));
}

exports.onNewReport = onDocumentCreated('risk_reports/{reportId}', async (event) => {
  if (!event.data || !event.id) return;
  const admins = await db.collection('users').where('role', '==', 'admin')
    .limit(100).get();
  await Promise.all(admins.docs.map((admin) =>
    notify(admin.id, event.params.reportId, event.id, {
      kind: 'new_report', title: 'New community report',
      body: 'A community report is awaiting admin review.',
    }).catch((error) => logger.error('Admin notification failed', error))));
});

exports.onReviewChange = onDocumentUpdated('risk_reports/{reportId}', async (event) => {
  if (!event.data || !event.id) return;
  const before = event.data.before.data();
  const after = event.data.after.data();
  const message = reviewMessage(before, after);
  if (!message || !after.userId) return;
  await notify(after.userId, event.params.reportId, event.id, message);
});
