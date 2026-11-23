/* eslint-disable @typescript-eslint/no-require-imports */
// Creates or updates the SkillBridge staff (SUPER_ADMIN) account. Run by the
// project owner only, from this folder, with the service account in
// .env.local and the sign-in details in the environment:
//
//   $env:ADMIN_EMAIL = 'new@address'; $env:ADMIN_PASSWORD = '...'
//   $env:ADMIN_CURRENT_EMAIL = 'old@address'   # optional: rename that account
//   node --env-file=.env.local create-admin.js
//
// With ADMIN_CURRENT_EMAIL, the existing admin keeps its account (same uid,
// data and access) and gets the new email and password; otherwise the
// account with ADMIN_EMAIL is updated, or created if there is none.
// Staff passwords can't be reset with "Forgot password" (app or website);
// this script is the way to change them.
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
});

async function findByEmail(email) {
  try {
    return await getAuth().getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') return null;
    throw error;
  }
}

async function createAdmin() {
  const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD;
  const currentEmail = process.env.ADMIN_CURRENT_EMAIL?.trim().toLowerCase();
  if (!email || !password) {
    throw new Error('Set ADMIN_EMAIL and ADMIN_PASSWORD before running this script.');
  }

  let userRecord = null;
  if (currentEmail && currentEmail !== email) {
    userRecord = await findByEmail(currentEmail);
    if (!userRecord) throw new Error(`No account with ADMIN_CURRENT_EMAIL (${currentEmail}).`);
    if (await findByEmail(email)) throw new Error(`Another account already uses ${email}.`);
    console.log('Renaming the existing admin account and setting the new password...');
    userRecord = await getAuth().updateUser(userRecord.uid, { email, password, emailVerified: true });
  } else {
    userRecord = await findByEmail(email);
    if (userRecord) {
      console.log('Admin account exists. Updating its password...');
      userRecord = await getAuth().updateUser(userRecord.uid, { password, emailVerified: true });
    } else {
      console.log('Creating the admin account...');
      userRecord = await getAuth().createUser({ email, password, emailVerified: true });
    }
  }

  console.log('Setting the SUPER_ADMIN claim...');
  await getAuth().setCustomUserClaims(userRecord.uid, { role: 'SUPER_ADMIN' });
  // Sign out existing sessions so the old password stops working everywhere.
  await getAuth().revokeRefreshTokens(userRecord.uid);

  // Profile in the shape the app reads (dates as Firestore timestamps).
  const ref = getFirestore().collection('users').doc(userRecord.uid);
  const existing = await ref.get();
  await ref.set({
    uid: userRecord.uid,
    email,
    displayName: existing.get('displayName') || existing.get('name') || 'SkillBridge Admin',
    role: 'SUPER_ADMIN',
    isActive: true,
    isEmailVerified: true,
    updatedAt: FieldValue.serverTimestamp(),
    ...(existing.exists && existing.get('createdAt') && typeof existing.get('createdAt') !== 'string'
      ? {}
      : { createdAt: FieldValue.serverTimestamp() }),
  }, { merge: true });

  console.log('Done. Admin account:', userRecord.uid, email);
}

createAdmin()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Error creating/updating the admin account:', error.message || error);
    process.exit(1);
  });
