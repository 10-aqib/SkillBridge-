// Emulator tests for the live-rules hotfix (demo project, never production).
const { test, before, after } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, updateDoc, getDoc, collection, addDoc } = require('firebase/firestore');

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-hotfix',
    firestore: { rules: fs.readFileSync(path.join(__dirname, 'firestore.rules'), 'utf8'), host: '127.0.0.1', port: 8287 },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'users/admin1'), { role: 'admin', displayName: 'Staff' });
    await setDoc(doc(db, 'users/client1'), { role: 'client', displayName: 'C' });
    await setDoc(doc(db, 'users/blank1'), { role: '', displayName: 'B' });
    await setDoc(doc(db, 'jobs/j1'), { clientId: 'client1', title: 'x' });
  });
});
after(async () => { await env.cleanup(); });

const db = (uid) => env.authenticatedContext(uid).firestore();

test('sign-up as client or worker still works', async () => {
  await assertSucceeds(setDoc(doc(db('new1'), 'users/new1'), { role: 'client', displayName: 'N' }));
  await assertSucceeds(setDoc(doc(db('new2'), 'users/new2'), { role: 'worker', displayName: 'N' }));
  await assertSucceeds(setDoc(doc(db('new3'), 'users/new3'), { displayName: 'no role yet' }));
});
test('cannot sign up as admin', async () => {
  await assertFails(setDoc(doc(db('evil1'), 'users/evil1'), { role: 'admin', displayName: 'E' }));
  await assertFails(setDoc(doc(db('evil2'), 'users/evil2'), { role: 'SUPER_ADMIN' }));
});
test('cannot change own role to admin', async () => {
  await assertFails(updateDoc(doc(db('client1'), 'users/client1'), { role: 'admin' }));
  await assertFails(setDoc(doc(db('client1'), 'users/client1'), { role: 'admin', displayName: 'C' }));
});
test('cannot switch client to worker', async () => {
  await assertFails(updateDoc(doc(db('client1'), 'users/client1'), { role: 'worker' }));
});
test('a user without a role can pick client or worker once', async () => {
  await assertFails(updateDoc(doc(db('blank1'), 'users/blank1'), { role: 'admin' }));
  await assertSucceeds(updateDoc(doc(db('blank1'), 'users/blank1'), { role: 'worker' }));
  await assertFails(updateDoc(doc(db('blank1'), 'users/blank1'), { role: 'client' }));
});
test('normal profile edits still work', async () => {
  await assertSucceeds(updateDoc(doc(db('client1'), 'users/client1'), { displayName: 'Changed', city: 'Lahore' }));
});
test('cannot edit someone else', async () => {
  await assertFails(updateDoc(doc(db('client1'), 'users/blank1'), { displayName: 'x' }));
});
test('staff can still set roles', async () => {
  await assertSucceeds(updateDoc(doc(db('admin1'), 'users/client1'), { role: 'worker' }));
});
test('rest of the live rules unchanged (spot checks)', async () => {
  await assertSucceeds(getDoc(doc(db('client1'), 'jobs/j1')));
  await assertSucceeds(addDoc(collection(db('anyone'), 'notifications'), { userId: 'x' }));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'jobs/j1')));
});
