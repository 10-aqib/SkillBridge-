/* eslint-disable @typescript-eslint/no-require-imports */
const fs = require('fs');
const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const envContent = fs.readFileSync('.env.local', 'utf8');
const envConfig = {};
envContent.split(/\r?\n/).forEach(line => {
  const match = line.match(/^([^=]+)=(.*)$/);
  if (match) {
    let key = match[1].trim();
    let val = match[2].trim();
    if (val.startsWith('"') && val.endsWith('"')) {
      val = val.slice(1, -1);
    }
    envConfig[key] = val;
  }
});

initializeApp({
  credential: cert({
    projectId: envConfig.FIREBASE_PROJECT_ID,
    clientEmail: envConfig.FIREBASE_CLIENT_EMAIL,
    privateKey: envConfig.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
  }),
});

async function listAdmins() {
  console.log('=== Firebase Auth Users ===');
  const authUsers = await getAuth().listUsers(1000);
  for (const u of authUsers.users) {
    console.log(`Email: ${u.email} | UID: ${u.uid} | Claims: ${JSON.stringify(u.customClaims || {})}`);
  }

  console.log('\n=== Firestore Users with Admin Role ===');
  const firestoreUsers = await getFirestore().collection('users').get();
  for (const doc of firestoreUsers.docs) {
    const data = doc.data();
    if (data.role && data.role.toLowerCase().includes('admin')) {
      console.log(`Doc ID: ${doc.id} | Email: ${data.email} | Role: ${data.role} | Name: ${data.name || data.fullName}`);
    }
  }
}

listAdmins()
  .then(() => process.exit(0))
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
