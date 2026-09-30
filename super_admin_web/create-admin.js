const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
});

async function createAdmin() {
  const email = 'ak9024706@gmail.com';
  const password = 'skyblue@1';

  try {
    let userRecord;
    try {
      userRecord = await getAuth().getUserByEmail(email);
      console.log('User already exists. Updating password...');
      userRecord = await getAuth().updateUser(userRecord.uid, { password });
    } catch (error) {
      if (error.code === 'auth/user-not-found') {
        console.log('Creating new user...');
        userRecord = await getAuth().createUser({
          email,
          password,
          emailVerified: true,
        });
      } else {
        throw error;
      }
    }

    console.log('Setting custom claims for SUPER_ADMIN...');
    await getAuth().setCustomUserClaims(userRecord.uid, {
      role: 'SUPER_ADMIN',
    });
    
    // Create the firestore document
    await getFirestore().collection('users').doc(userRecord.uid).set({
      email,
      role: 'SUPER_ADMIN',
      name: 'Aqib (Admin)',
      createdAt: new Date().toISOString()
    }, { merge: true });

    console.log('Successfully created/updated admin user:', userRecord.uid);
    process.exit(0);
  } catch (error) {
    console.error('Error creating admin user:', error);
    process.exit(1);
  }
}

createAdmin();
