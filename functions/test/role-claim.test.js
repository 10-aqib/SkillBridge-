// Unit tests for the role-claim decision (no Firebase needed).
// Run: npx tsc --skipLibCheck -p . --outDir .test-build && node --test test/
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { nextRoleClaim } = require('../.test-build/auth.js');

test('first client/worker choice is mirrored to the claim', () => {
  assert.equal(nextRoleClaim(undefined, 'worker', 'client'), 'worker');
  assert.equal(nextRoleClaim('', 'client', undefined), 'client');
});

test('a forged staff role in Firestore is ignored', () => {
  assert.equal(nextRoleClaim('', 'admin', 'client'), null);
  assert.equal(nextRoleClaim('client', 'SUPER_ADMIN', 'client'), null);
  assert.equal(nextRoleClaim('', 'anything', undefined), null);
});

test('staff claims are never replaced or removed', () => {
  assert.equal(nextRoleClaim('', 'client', 'admin'), null);
  assert.equal(nextRoleClaim(undefined, 'worker', 'SUPER_ADMIN'), null);
});

test('no write when the claim already matches', () => {
  assert.equal(nextRoleClaim('', 'worker', 'worker'), null);
  assert.equal(nextRoleClaim('worker', 'worker', 'worker'), null);
});
