'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { reviewMessage } = require('../messages');

test('does not notify for an unrelated update', () => {
  assert.equal(reviewMessage({ status: 'active', verificationStatus: 'pending' },
    { status: 'active', verificationStatus: 'pending' }), null);
});

test('uses accurate verification language without private details', () => {
  const before = { status: 'active', verificationStatus: 'pending' };
  const verified = reviewMessage(before, {
    status: 'active', verificationStatus: 'verified', title: 'secret', latitude: 1,
  });
  assert.equal(verified.kind, 'report_verified');
  assert.doesNotMatch(JSON.stringify(verified), /secret|latitude/);
  assert.match(verified.body, /verified/);
  assert.equal(reviewMessage(before, {
    status: 'active', verificationStatus: 'rejected',
  }).kind, 'report_rejected');
});

test('notifies about resolution without claiming a risk is verified', () => {
  const message = reviewMessage(
    { status: 'active', verificationStatus: 'pending' },
    { status: 'resolved', verificationStatus: 'pending' });
  assert.equal(message.kind, 'report_resolved');
  assert.doesNotMatch(message.body, /verified/);
});
