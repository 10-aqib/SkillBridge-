/* eslint-disable @typescript-eslint/no-require-imports */
// Creates or updates the SkillBridge staff (SUPER_ADMIN) account. Run by the
// project owner only, from this folder, with the service account in
// .env.local:
//
//   $env:ADMIN_USERNAME = 'skillbridge@admin'
//   node --env-file=.env.local create-admin.js
//
// Staff sign in with a username (app and admin website). Firebase needs an
// email, so the username becomes an internal address on the project's own
// Firebase domain, which has no mailbox:
//   skillbridge@admin  ->  skillbridge.admin@skill-bridge-c68c3.firebaseapp.com
// (same rule as AppConstants.staffEmailForUsername and src/lib/auth/staff-login.ts).
// ADMIN_EMAIL can be set instead of ADMIN_USERNAME to use a real address.
//
// The new password is asked for in the window (hidden while typed, entered
// twice). ADMIN_PASSWORD may be set instead for unattended use.
//
// Which account is changed:
// * ADMIN_CURRENT_EMAIL set: that account is renamed to ADMIN_EMAIL;
// * otherwise, if an account already uses ADMIN_EMAIL: its password is set;
// * otherwise, if exactly one SUPER_ADMIN account exists: it is renamed to
//   ADMIN_EMAIL (same uid, data and access);
// * otherwise a new admin account is created.
// Staff passwords can't be reset with "Forgot password" (app or website);
// this script is the way to change them. Existing admin sessions are signed
// out, so the old password stops working everywhere.
const readline = require('node:readline');
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

/** Asks a question without echoing what is typed. */
function askHidden(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: true });
    rl._writeToOutput = (s) => {
      if (s.includes(question)) rl.output.write(s);
    };
    rl.question(question, (answer) => {
      rl.close();
      process.stdout.write('\n');
      resolve(answer);
    });
  });
}

async function readPassword() {
  if (process.env.ADMIN_PASSWORD) return process.env.ADMIN_PASSWORD;
  const first = await askHidden('New admin password (hidden): ');
  const second = await askHidden('Type it again: ');
  if (first !== second) throw new Error('The two passwords are different. Nothing was changed.');
  if (first.length < 8) throw new Error('Use at least 8 characters. Nothing was changed.');
  return first;
}

const STAFF_EMAIL_DOMAIN = 'skill-bridge-c68c3.firebaseapp.com';
const STAFF_USERNAME = /^[a-z0-9._-]{2,40}@[a-z0-9-]{2,30}$/;

function emailForUsername(username) {
  const v = username.trim().toLowerCase();
  if (!STAFF_USERNAME.test(v)) {
    throw new Error('ADMIN_USERNAME must look like name@word (letters, digits, . _ -), e.g. skillbridge@admin.');
  }
  return `${v.replace('@', '.')}@${STAFF_EMAIL_DOMAIN}`;
}

async function findByEmail(email) {
  try {
    return await getAuth().getUserByEmail(email);
  } catch (error) {
    if (error.code === 'auth/user-not-found') return null;
    throw error;
  }
}

/** The one existing SUPER_ADMIN account, found by its profile role. */
async function findSoleSuperAdmin() {
  const snap = await getFirestore().collection('users').where('role', '==', 'SUPER_ADMIN').get();
  const found = [];
  for (const doc of snap.docs) {
    try {
      found.push(await getAuth().getUser(doc.id));
    } catch {
      // Profile without a sign-in account: ignore.
    }
  }
  if (found.length > 1) {
    throw new Error(`${found.length} admin accounts exist (${found.map((u) => u.email).join(', ')}). `
      + 'Set ADMIN_CURRENT_EMAIL to the one to rename.');
  }
  return found[0] || null;
}

async function createAdmin() {
  const username = process.env.ADMIN_USERNAME?.trim().toLowerCase();
  const email = username ? emailForUsername(username) : process.env.ADMIN_EMAIL?.trim().toLowerCase();
  const currentEmail = process.env.ADMIN_CURRENT_EMAIL?.trim().toLowerCase();
  if (!email) throw new Error('Set ADMIN_USERNAME (or ADMIN_EMAIL) before running this script.');
  const signInName = username || email;

  // Decide what to change before asking for the password.
  let target = null;
  let rename = false;
  if (currentEmail && currentEmail !== email) {
    target = await findByEmail(currentEmail);
    if (!target) throw new Error(`No account with ADMIN_CURRENT_EMAIL (${currentEmail}).`);
    rename = true;
  } else {
    target = await findByEmail(email);
    if (!target) {
      target = await findSoleSuperAdmin();
      rename = Boolean(target);
    }
  }
  if (rename && (await findByEmail(email))) throw new Error(`Another account already uses ${signInName}.`);
  console.log(target
    ? (rename ? `Admin account found (${target.email}); it will sign in as ${signInName}.` : `Updating the password of ${signInName}.`)
    : `No admin account yet; creating ${signInName}.`);

  const password = await readPassword();

  let userRecord;
  if (target) {
    userRecord = await getAuth().updateUser(target.uid, { ...(rename ? { email } : {}), password, emailVerified: true });
  } else {
    userRecord = await getAuth().createUser({ email, password, emailVerified: true });
  }

  await getAuth().setCustomUserClaims(userRecord.uid, { role: 'SUPER_ADMIN' });
  await getAuth().revokeRefreshTokens(userRecord.uid);

  // Profile in the shape the app reads (dates as Firestore timestamps).
  const ref = getFirestore().collection('users').doc(userRecord.uid);
  const existing = await ref.get();
  const createdAt = existing.exists ? existing.get('createdAt') : undefined;
  await ref.set({
    uid: userRecord.uid,
    email,
    displayName: existing.get('displayName') || existing.get('name') || 'SkillBridge Admin',
    role: 'SUPER_ADMIN',
    isActive: true,
    isEmailVerified: true,
    updatedAt: FieldValue.serverTimestamp(),
    ...(createdAt && typeof createdAt !== 'string' ? {} : { createdAt: FieldValue.serverTimestamp() }),
  }, { merge: true });

  console.log(`Done. The admin signs in as ${signInName} with the new password. Old sessions are signed out.`);
}

createAdmin()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('Not changed:', error.message || error);
    process.exit(1);
  });
