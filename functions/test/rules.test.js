'use strict';

// Requires a running Firestore emulator:
// firebase emulators:exec --only firestore "cd functions && npm run test:rules"
const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, serverTimestamp } =
  require('firebase/firestore');

const rules = fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8');

test('Firestore enforces profile, author and admin roles', async () => {
  const env = await initializeTestEnvironment({
    projectId: 'demo-risk-track-rules',
    firestore: { host: '127.0.0.1', port: 8080, rules },
  });
  try {
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      for (const [uid, role] of [['member', 'user'], ['other', 'user'],
        ['reviewer', 'admin']]) {
        await setDoc(doc(db, 'users', uid), {
          uid, fullName: uid === 'member' ? 'Test Member' : 'Another Member',
          email: `${uid}@example.org`, photoUrl: '', role,
          createdAt: new Date(),
        });
      }
    });
    const fresh = env.authenticatedContext('fresh',
      { email: 'fresh@example.org' }).firestore();
    const freshProfile = doc(fresh, 'users', 'fresh');
    const freshData = { uid: 'fresh', fullName: 'Fresh Member',
      email: 'fresh@example.org', photoUrl: '',
      createdAt: serverTimestamp() };
    await assertFails(setDoc(freshProfile, { ...freshData, role: 'admin' }));
    await assertSucceeds(setDoc(freshProfile,
      { ...freshData, role: 'user' }));

    const member = env.authenticatedContext('member',
      { email: 'member@example.org' }).firestore();
    const other = env.authenticatedContext('other',
      { email: 'other@example.org' }).firestore();
    const admin = env.authenticatedContext('reviewer',
      { email: 'reviewer@example.org' }).firestore();
    const memberProfile = doc(member, 'users', 'member');
    const report = doc(member, 'risk_reports', 'report-1');

    await assertFails(getDoc(doc(other, 'users', 'member')));
    await assertSucceeds(getDoc(memberProfile));
    await assertFails(updateDoc(memberProfile, { role: 'admin' }));
    await assertSucceeds(updateDoc(memberProfile, { fullName: 'New Name' }));
    await assertSucceeds(setDoc(report, {
      reportId: 'report-1', userId: 'member', reporterName: 'New Name',
      title: 'Road flooding reported',
      description: 'Rainwater is covering the main road this morning.',
      category: 'Flood', latitude: 6.5244, longitude: 3.3792,
      address: 'Lagos, Nigeria', imageUrl: '', status: 'active',
      verificationStatus: 'pending', createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
    }));
    const flag = doc(member, 'report_flags', 'report-1_member');
    await assertSucceeds(setDoc(flag, { reportId: 'report-1',
      userId: 'member', reason: 'The road has since been repaired.',
      createdAt: serverTimestamp() }));
    await assertFails(setDoc(flag, { reportId: 'report-1',
      userId: 'member', reason: 'Trying to submit a duplicate flag.',
      createdAt: serverTimestamp() }));
    await assertFails(updateDoc(report, { verificationStatus: 'verified',
      updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(other, 'risk_reports', 'report-1'), {
      status: 'resolved', updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(admin, 'risk_reports', 'report-1'), {
      verificationStatus: 'verified', updatedAt: serverTimestamp(),
    }));
    await assertSucceeds(updateDoc(doc(admin, 'users', 'other'),
      { role: 'admin' }));
    await assertFails(updateDoc(doc(admin, 'users', 'reviewer'),
      { role: 'user' }));
    await assertFails(setDoc(doc(member, 'users', 'member', 'notifications', 'fake'), {
      title: 'Spoofed', read: false,
    }));
    assert.equal((await getDoc(doc(member, 'risk_reports', 'report-1')))
      .data().verificationStatus, 'verified');
  } finally {
    await env.cleanup();
  }
});
