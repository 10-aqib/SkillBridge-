// Security-rules tests (Phase 2B profiles/verification, Phase 3A jobs, Phase 3B proposals/chat). Runs only against the local
// emulators under the fake project "demo-skillbridge".
import { after, before, beforeEach, describe, test } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import assert from 'node:assert/strict';
import {
  GeoPoint, Timestamp, collection, deleteDoc, deleteField, doc, getDoc, getDocs, limit, orderBy, query,
  serverTimestamp, setDoc, updateDoc, where, writeBatch,
} from 'firebase/firestore';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

let env;
const png = new Uint8Array([137, 80, 78, 71, 13, 10, 26, 10]);
const pdf = new TextEncoder().encode('%PDF-1.4 test');

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-skillbridge',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8181 },
    storage: { rules: readFileSync('../storage.rules', 'utf8'), host: '127.0.0.1', port: 9198 },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
});

const user = (uid) => env.authenticatedContext(uid).firestore();
const admin = () => env.authenticatedContext('staff', { role: 'admin' });
const baseProfile = (uid, role) => ({
  uid, role, email: `${uid}@example.com`, displayName: 'Test', phoneNumber: '',
  isActive: true, isCnicVerified: false, isEmailVerified: false, isPhoneVerified: false,
});
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => setDoc(doc(ctx.firestore(), path), data));
}

describe('users: role assignment', () => {
  test('a person can create their own client or worker profile', async () => {
    await assertSucceeds(setDoc(doc(user('c1'), 'users/c1'), baseProfile('c1', 'client')));
    await assertSucceeds(setDoc(doc(user('w1'), 'users/w1'), baseProfile('w1', 'worker')));
  });

  test('nobody can create a profile with an admin role', async () => {
    await assertFails(setDoc(doc(user('u1'), 'users/u1'), baseProfile('u1', 'admin')));
    await assertFails(setDoc(doc(user('u2'), 'users/u2'), baseProfile('u2', 'SUPER_ADMIN')));
  });

  test('cannot create a profile for someone else', async () => {
    await assertFails(setDoc(doc(user('u1'), 'users/other'), baseProfile('other', 'client')));
  });

  test('cannot create a pre-verified or inactive profile', async () => {
    await assertFails(setDoc(doc(user('u1'), 'users/u1'), { ...baseProfile('u1', 'worker'), isCnicVerified: true }));
    await assertFails(setDoc(doc(user('u2'), 'users/u2'), {
      ...baseProfile('u2', 'worker'), workerProfile: { headline: 'x', isVerified: true },
    }));
    await assertFails(setDoc(doc(user('u3'), 'users/u3'), { ...baseProfile('u3', 'client'), isActive: false }));
  });

  test('a legacy profile with role "" can choose client or worker once', async () => {
    await seed('users/g1', baseProfile('g1', ''));
    await assertSucceeds(updateDoc(doc(user('g1'), 'users/g1'), { role: 'worker' }));
    await assertFails(updateDoc(doc(user('g1'), 'users/g1'), { role: 'client' }));
  });

  test('a legacy profile with role "" cannot become admin', async () => {
    await seed('users/g2', baseProfile('g2', ''));
    await assertFails(updateDoc(doc(user('g2'), 'users/g2'), { role: 'admin' }));
  });

  test('an existing client cannot switch role or become admin', async () => {
    await seed('users/c1', baseProfile('c1', 'client'));
    await assertFails(updateDoc(doc(user('c1'), 'users/c1'), { role: 'worker' }));
    await assertFails(updateDoc(doc(user('c1'), 'users/c1'), { role: 'admin' }));
  });

  test('legacy profiles without a role field can still update other fields', async () => {
    const { role, ...noRole } = baseProfile('l1', 'client');
    await seed('users/l1', noRole);
    await assertSucceeds(updateDoc(doc(user('l1'), 'users/l1'), { displayName: 'New name' }));
  });

  test('owners can edit ordinary profile fields', async () => {
    await seed('users/c1', baseProfile('c1', 'client'));
    await assertSucceeds(updateDoc(doc(user('c1'), 'users/c1'), {
      displayName: 'Sana', phoneNumber: '+923001234567', city: 'Lahore', photoUrl: 'https://example.com/p.jpg',
    }));
  });
});

describe('users: protected flags', () => {
  test('a suspended account cannot reactivate itself', async () => {
    await seed('users/s1', { ...baseProfile('s1', 'client'), isActive: false });
    await assertFails(updateDoc(doc(user('s1'), 'users/s1'), { isActive: true }));
  });

  test('a worker cannot mark themselves verified, but can submit (pending)', async () => {
    await seed('users/w1', { ...baseProfile('w1', 'worker'), workerProfile: { headline: 'h', isVerified: false } });
    await assertFails(updateDoc(doc(user('w1'), 'users/w1'), { 'workerProfile.isVerified': true }));
    await assertFails(updateDoc(doc(user('w1'), 'users/w1'), { 'workerProfile.verificationStatus': 'verified' }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'users/w1'), { 'workerProfile.verificationStatus': 'pending' }));
  });

  test('staff (custom claim) can still update any profile', async () => {
    await seed('users/w1', { ...baseProfile('w1', 'worker'), workerProfile: { isVerified: false } });
    await assertSucceeds(updateDoc(doc(admin().firestore(), 'users/w1'), {
      'workerProfile.isVerified': true, 'workerProfile.verificationStatus': 'verified',
    }));
  });
});

describe('users: CNIC never public', () => {
  test('cannot create a profile with a public CNIC', async () => {
    await assertFails(setDoc(doc(user('w1'), 'users/w1'), { ...baseProfile('w1', 'worker'), cnicNumber: '35202-1234567-1' }));
  });

  test('cannot add or change a CNIC on the public profile', async () => {
    await seed('users/w1', baseProfile('w1', 'worker'));
    await assertFails(updateDoc(doc(user('w1'), 'users/w1'), { cnicNumber: '35202-1234567-1' }));
    await seed('users/w2', { ...baseProfile('w2', 'worker'), cnicNumber: '35202-1234567-1' });
    await assertFails(updateDoc(doc(user('w2'), 'users/w2'), { cnicNumber: '35202-7654321-1' }));
  });

  test('a legacy public CNIC can be kept unchanged or removed by its owner', async () => {
    await seed('users/w2', { ...baseProfile('w2', 'worker'), cnicNumber: '35202-1234567-1' });
    await assertSucceeds(updateDoc(doc(user('w2'), 'users/w2'), { displayName: 'Renamed' }));
    await assertSucceeds(updateDoc(doc(user('w2'), 'users/w2'), { cnicNumber: deleteField() }));
  });
});

describe('users/{uid}/private/verification', () => {
  const submission = {
    cnicNumber: '35202-1234567-1',
    documents: ['users/w1/verificationDocuments/cnic-front.jpg'],
    status: 'pending',
  };

  test('owner can submit and read their own verification', async () => {
    await assertSucceeds(setDoc(doc(user('w1'), 'users/w1/private/verification'), submission));
    await assertSucceeds(getDoc(doc(user('w1'), 'users/w1/private/verification')));
  });

  test('other signed-in users cannot read it', async () => {
    await seed('users/w1/private/verification', submission);
    await assertFails(getDoc(doc(user('c1'), 'users/w1/private/verification')));
  });

  test('staff can read it', async () => {
    await seed('users/w1/private/verification', submission);
    await assertSucceeds(getDoc(doc(admin().firestore(), 'users/w1/private/verification')));
  });

  test('owner cannot mark their submission verified', async () => {
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), { ...submission, status: 'verified' }));
  });

  test('CNIC format and document count are validated', async () => {
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), { ...submission, cnicNumber: '123' }));
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), { ...submission, documents: [] }));
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), { ...submission, extra: 'x' }));
  });

  test('document entries must be files in the owner\'s private folder', async () => {
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), {
      ...submission, documents: ['users/other/verificationDocuments/x.jpg'],
    }));
    await assertFails(setDoc(doc(user('w1'), 'users/w1/private/verification'), {
      ...submission, documents: ['users/w1/portfolio/x.jpg'],
    }));
    await assertSucceeds(setDoc(doc(user('w1'), 'users/w1/private/verification'), {
      ...submission,
      documents: ['users/w1/verificationDocuments/a.jpg', 'users/w1/verificationDocuments/b.pdf'],
    }));
  });

  test('cannot write another person\'s verification', async () => {
    await assertFails(setDoc(doc(user('c1'), 'users/w1/private/verification'), submission));
  });
});

describe('storage', () => {
  const st = (uid, claims) => (claims ? env.authenticatedContext(uid, claims) : env.authenticatedContext(uid)).storage();
  const anon = () => env.unauthenticatedContext().storage();

  test('verification documents are NOT publicly readable', async () => {
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/verificationDocuments/cnic.pdf'), pdf, { contentType: 'application/pdf' }));
    await assertFails(getBytes(ref(anon(), 'users/w1/verificationDocuments/cnic.pdf')));
    await assertFails(getBytes(ref(st('c1'), 'users/w1/verificationDocuments/cnic.pdf')));
  });

  test('owner and staff can read verification documents', async () => {
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/verificationDocuments/cnic.jpg'), png, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(st('w1'), 'users/w1/verificationDocuments/cnic.jpg')));
    await assertSucceeds(getBytes(ref(st('staff', { role: 'admin' }), 'users/w1/verificationDocuments/cnic.jpg')));
  });

  test('profile photos and portfolio stay public; only the owner can write', async () => {
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/profile/avatar.jpg'), png, { contentType: 'image/jpeg' }));
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/portfolio/a.jpg'), png, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(anon(), 'users/w1/portfolio/a.jpg')));
    await assertFails(uploadBytes(ref(st('c1'), 'users/w1/portfolio/b.jpg'), png, { contentType: 'image/jpeg' }));
  });

  test('owner can delete their own portfolio image; others cannot', async () => {
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/portfolio/a.jpg'), png, { contentType: 'image/jpeg' }));
    await assertFails(deleteObject(ref(st('c1'), 'users/w1/portfolio/a.jpg')));
    await assertSucceeds(deleteObject(ref(st('w1'), 'users/w1/portfolio/a.jpg')));
  });

  test('files directly under users/{uid}/ stay public (unchanged behaviour)', async () => {
    await assertSucceeds(uploadBytes(ref(st('w1'), 'users/w1/legacy.jpg'), png, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(anon(), 'users/w1/legacy.jpg')));
  });

  test('non-image, non-PDF uploads are rejected', async () => {
    await assertFails(uploadBytes(ref(st('w1'), 'users/w1/portfolio/x.txt'), pdf, { contentType: 'text/plain' }));
  });
});

// ── Phase 3A: jobs ─────────────────────────────────────────────────────────

const jobData = (clientId, extra = {}) => ({
  clientId, clientName: 'Ayesha', clientPhotoUrl: null,
  title: 'Fix kitchen wiring', description: 'Two sockets and one light need rewiring safely.',
  categoryId: 'electrician', categoryName: 'Electrician', requiredSkills: ['House wiring'], jobType: 'temporary',
  budgetMin: 2000, budgetMax: 3000, budgetType: 'fixed', budgetBand: '2k_5k',
  location: null, address: 'Gulberg', city: 'Lahore', status: 'open', urgency: 'within_3_days', images: [],
  totalProposals: 0, selectedWorkerId: null, selectedWorkerName: null, startDate: null, endDate: null,
  isPaid: false, searchKeywords: ['fix', 'kitchen', 'wiring'],
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
});
const anonDb = () => env.unauthenticatedContext().firestore();

async function seedUsers() {
  await seed('users/c1', baseProfile('c1', 'client'));
  await seed('users/c2', baseProfile('c2', 'client'));
  await seed('users/w1', baseProfile('w1', 'worker'));
  await seed('users/w2', baseProfile('w2', 'worker'));
  await seed('users/cs', { ...baseProfile('cs', 'client'), isActive: false });
  await seed('users/ws', { ...baseProfile('ws', 'worker'), isActive: false });
}
const openFeed = (db) => query(collection(db, 'jobs'),
  where('status', '==', 'open'), where('selectedWorkerId', '==', null), orderBy('createdAt', 'desc'));

describe('jobs: creating', () => {
  beforeEach(seedUsers);

  test('1. an authenticated client creates a job for themselves', async () => {
    await assertSucceeds(setDoc(doc(user('c1'), 'jobs/j1'), jobData('c1')));
  });

  test('2. a worker cannot create a job, even naming a client', async () => {
    await assertFails(setDoc(doc(user('w1'), 'jobs/j1'), jobData('w1')));
    await assertFails(setDoc(doc(user('w1'), 'jobs/j2'), jobData('c1')));
  });

  test('3. an unauthenticated user cannot create a job', async () => {
    await assertFails(setDoc(doc(anonDb(), 'jobs/j1'), jobData('c1')));
  });

  test('a client cannot post on behalf of another client', async () => {
    await assertFails(setDoc(doc(user('c1'), 'jobs/j1'), jobData('c2')));
  });

  test('a suspended client cannot post', async () => {
    await assertFails(setDoc(doc(user('cs'), 'jobs/j1'), jobData('cs')));
  });

  test('creation time must be the server time; counters and payment start empty', async () => {
    await assertFails(setDoc(doc(user('c1'), 'jobs/a'), jobData('c1', { createdAt: Timestamp.fromDate(new Date(2020, 0, 1)) })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/b'), jobData('c1', { totalProposals: 7 })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/c'), jobData('c1', { isPaid: true })));
  });

  test('unknown or staff-only fields and invalid content are rejected', async () => {
    await assertFails(setDoc(doc(user('c1'), 'jobs/a'), jobData('c1', { isFeatured: true })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/b'), jobData('c1', { title: 'Fix' })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/c'), jobData('c1', { budgetMin: 5000, budgetMax: 1000 })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/d'), jobData('c1', { budgetType: 'free' })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/e'), jobData('c1', { status: 'completed' })));
  });

  test('direct request and direct hire to a worker still work (not to yourself)', async () => {
    await assertSucceeds(setDoc(doc(user('c1'), 'jobs/dr'), jobData('c1', { selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' })));
    await assertSucceeds(setDoc(doc(user('c1'), 'jobs/dh'), jobData('c1', { status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' })));
    await assertFails(setDoc(doc(user('c1'), 'jobs/self'), jobData('c1', { status: 'assigned', selectedWorkerId: 'c1' })));
  });
});

describe('jobs: editing and status', () => {
  beforeEach(async () => {
    await seedUsers();
    await seed('jobs/j1', jobData('c1'));
  });

  test('4. a client edits their own open job', async () => {
    await assertSucceeds(updateDoc(doc(user('c1'), 'jobs/j1'), {
      title: 'Fix kitchen and lounge wiring', budgetMax: 4000, searchKeywords: ['fix', 'lounge'], updatedAt: serverTimestamp(),
    }));
  });

  test('5. a client cannot edit another client\'s job', async () => {
    await assertFails(updateDoc(doc(user('c2'), 'jobs/j1'), { title: 'Taken over by someone else' }));
  });

  test('6. a worker cannot edit a job', async () => {
    await assertFails(updateDoc(doc(user('w1'), 'jobs/j1'), { title: 'Edited by a worker' }));
    await assertFails(updateDoc(doc(user('w1'), 'jobs/j1'), { status: 'cancelled' }));
  });

  test('7. nobody can change who owns a job', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { clientId: 'c2' }));
    await assertFails(updateDoc(doc(user('c2'), 'jobs/j1'), { clientId: 'c2' }));
  });

  test('8. protected fields cannot be modified', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { totalProposals: 50 }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { isPaid: true }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { createdAt: Timestamp.fromDate(new Date(2030, 0, 1)) }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { isFlagged: false }));
  });

  test('close and reopen; a closed job cannot be edited', async () => {
    await assertSucceeds(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'cancelled', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { title: 'Edited while closed' }));
    await assertSucceeds(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'open', updatedAt: serverTimestamp() }));
  });

  test('closing cannot sneak in other changes; invalid jumps are refused', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'cancelled', title: 'And a new title too' }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'completed' }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'deleted' }));
  });

  test('a cancelled direct request cannot be reopened as a public job', async () => {
    await seed('jobs/dr', jobData('c1', { status: 'cancelled', selectedWorkerId: 'w1' }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/dr'), { status: 'open' }));
  });

  test('hiring and work steps cannot be written by the owner or the worker (server only, Phase 4A)', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), {
      status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal', updatedAt: serverTimestamp(),
    }));
    await seed('jobs/h1', jobData('c1', { status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
    await assertFails(updateDoc(doc(user('w1'), 'jobs/h1'), { status: 'in_progress', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('w1'), 'jobs/h1'), { status: 'completed', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/h1'), { status: 'completed', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/h1'), { status: 'cancelled', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('w2'), 'jobs/h1'), { status: 'in_progress' }));
    await assertSucceeds(updateDoc(doc(admin().firestore(), 'jobs/h1'), { status: 'in_progress' }), 'trusted (Admin SDK / function)');
  });

  test('a directly requested worker can accept or decline, nothing more', async () => {
    await seed('jobs/dr', jobData('c1', { selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
    await assertFails(updateDoc(doc(user('w1'), 'jobs/dr'), { selectedWorkerId: 'w2' }));
    // Older direct requests (no contract) can only be declined (Phase 4A).
    await assertFails(updateDoc(doc(user('w1'), 'jobs/dr'), { status: 'assigned', selectedWorkerName: 'Bilal A.' }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'jobs/dr'), { status: 'cancelled' }));
  });

  test('only staff can delete jobs (history is kept)', async () => {
    await assertFails(deleteDoc(doc(user('c1'), 'jobs/j1')));
    await assertFails(deleteDoc(doc(user('w1'), 'jobs/j1')));
    await assertSucceeds(deleteDoc(doc(admin().firestore(), 'jobs/j1')));
  });

  test('staff can still moderate any field', async () => {
    await assertSucceeds(updateDoc(doc(admin().firestore(), 'jobs/j1'), { status: 'cancelled', isFlagged: true }));
  });
});

describe('jobs: reading and discovery', () => {
  beforeEach(async () => {
    await seedUsers();
    await seed('jobs/open1', jobData('c1'));
    await seed('jobs/closed1', jobData('c1', { status: 'cancelled' }));
    await seed('jobs/direct1', jobData('c1', { selectedWorkerId: 'w2', selectedWorkerName: 'Kamran' }));
    await seed('jobs/assigned1', jobData('c2', { status: 'assigned', selectedWorkerId: 'w2' }));
  });

  test('9. a worker reads a published job and the open-job feed', async () => {
    await assertSucceeds(getDoc(doc(user('w1'), 'jobs/open1')));
    const snap = await assertSucceeds(getDocs(openFeed(user('w1'))));
    assert.deepEqual(snap.docs.map((d) => d.id), ['open1']);
  });

  test('feed search, filter and budget-sort queries are allowed', async () => {
    const db = user('w1');
    const base = [where('status', '==', 'open'), where('selectedWorkerId', '==', null)];
    await assertSucceeds(getDocs(query(collection(db, 'jobs'), ...base, where('searchKeywords', 'array-contains', 'wiring'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDocs(query(collection(db, 'jobs'), ...base, where('categoryId', '==', 'electrician'), where('budgetBand', '==', '2k_5k'), orderBy('budgetMax', 'asc'))));
    await assertSucceeds(getDocs(query(collection(db, 'jobs'), ...base, where('requiredSkills', 'array-contains-any', ['House wiring']), limit(15))));
  });

  test('10. a worker cannot read closed, direct-request or assigned jobs of others', async () => {
    await assertFails(getDoc(doc(user('w1'), 'jobs/closed1')));
    await assertFails(getDoc(doc(user('w1'), 'jobs/direct1')));
    await assertFails(getDoc(doc(user('w1'), 'jobs/assigned1')));
    // A query that could include non-public jobs is refused outright.
    await assertFails(getDocs(query(collection(user('w1'), 'jobs'), where('status', '==', 'open'))));
    await assertFails(getDocs(collection(user('w1'), 'jobs')));
  });

  test('signed-out and suspended users cannot browse jobs', async () => {
    await assertFails(getDoc(doc(anonDb(), 'jobs/open1')));
    await assertFails(getDocs(openFeed(user('ws'))));
  });

  test('owners see all their jobs; the selected worker sees theirs', async () => {
    await assertSucceeds(getDocs(query(collection(user('c1'), 'jobs'), where('clientId', '==', 'c1'), orderBy('createdAt', 'desc'))));
    await assertSucceeds(getDoc(doc(user('c1'), 'jobs/closed1')));
    await assertSucceeds(getDoc(doc(user('w2'), 'jobs/direct1')));
    await assertSucceeds(getDocs(query(collection(user('w2'), 'jobs'), where('selectedWorkerId', '==', 'w2'), where('status', '==', 'open'))));
    await assertFails(getDocs(query(collection(user('c2'), 'jobs'), where('clientId', '==', 'c1'))));
  });
});

describe('storage: job photos', () => {
  const st = (uid) => env.authenticatedContext(uid).storage();
  test('the legacy shared jobs/ folder is no longer writable', async () => {
    await assertFails(uploadBytes(ref(st('c1'), 'jobs/j1/photo.jpg'), png, { contentType: 'image/jpeg' }));
  });
  test('job photos live in the client\'s own folder: owner writes, anyone reads', async () => {
    await assertSucceeds(uploadBytes(ref(st('c1'), 'users/c1/jobPhotos/a.jpg'), png, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(st('c2'), 'users/c1/jobPhotos/b.jpg'), png, { contentType: 'image/jpeg' }));
    await assertSucceeds(getBytes(ref(env.unauthenticatedContext().storage(), 'users/c1/jobPhotos/a.jpg')));
  });
});

// ── Phase 3B: proposals, acceptance, contracts, chat ──────────────────────

const proposalData = (jobId, workerId, clientId, extra = {}) => ({
  jobId, jobTitle: 'Fix kitchen wiring', workerId, workerName: 'Bilal', workerPhotoUrl: null, clientId,
  coverLetter: 'I have fixed many kitchen circuits and bring my own tester and spares.',
  proposedRate: 2500, rateType: 'fixed', estimatedDuration: '1 day', status: 'pending',
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), ...extra,
});

async function seedMarket() {
  await seedUsers();
  await seed('jobs/j1', jobData('c1'));
  await seed('jobs/closed1', jobData('c1', { status: 'cancelled' }));
  await seed('jobs/done1', jobData('c1', { status: 'completed', selectedWorkerId: 'w2' }));
  await seed('jobs/dr', jobData('c1', { selectedWorkerId: 'w2', selectedWorkerName: 'Kamran' }));
  await seed('jobs/other', jobData('c2'));
}

function acceptBatch(db, { jobId = 'j1', workerId = 'w1', others = [], contract = true } = {}) {
  const b = writeBatch(db);
  b.update(doc(db, `proposals/${jobId}_${workerId}`), { status: 'accepted', decidedAt: serverTimestamp(), updatedAt: serverTimestamp() });
  b.update(doc(db, `jobs/${jobId}`), { status: 'assigned', selectedWorkerId: workerId, selectedWorkerName: 'Bilal', updatedAt: serverTimestamp() });
  for (const o of others) {
    b.update(doc(db, `proposals/${jobId}_${o}`), { status: 'rejected', closedReason: 'filled', decidedAt: serverTimestamp(), updatedAt: serverTimestamp() });
  }
  if (contract) {
    b.set(doc(db, `contracts/${jobId}_${workerId}`), {
      jobId, proposalId: `${jobId}_${workerId}`, clientId: 'c1', workerId, agreedRate: 2500, rateType: 'fixed',
      totalAmount: 2500, paymentStatus: 'unpaid', status: 'active', createdAt: serverTimestamp(),
    });
  }
  return b;
}

// Phase 4A: hiring is server-only (acceptProposalCall). Tests that need a
// hired job seed exactly what that function writes.
async function seedHired({ jobId = 'j1', workerId = 'w1', others = [] } = {}) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    const b = writeBatch(db);
    b.update(doc(db, `proposals/${jobId}_${workerId}`), { status: 'accepted' });
    b.update(doc(db, `jobs/${jobId}`), { status: 'assigned', selectedWorkerId: workerId, selectedWorkerName: 'Bilal' });
    for (const o of others) b.update(doc(db, `proposals/${jobId}_${o}`), { status: 'rejected', closedReason: 'filled' });
    b.set(doc(db, `contracts/${jobId}_${workerId}`), {
      jobId, proposalId: `${jobId}_${workerId}`, clientId: 'c1', workerId, agreedRate: 2500, rateType: 'fixed',
      totalAmount: 2500, paymentStatus: 'unpaid', status: 'active', workStartedAt: null, submittedAt: null,
    });
    await b.commit();
  });
}

describe('proposals: submitting', () => {
  beforeEach(seedMarket);

  test('1. a worker submits a proposal to an open job', async () => {
    await assertSucceeds(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1')));
  });

  test('2. closed, completed and direct-request jobs cannot receive proposals', async () => {
    await assertFails(setDoc(doc(user('w1'), 'proposals/closed1_w1'), proposalData('closed1', 'w1', 'c1')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/done1_w1'), proposalData('done1', 'w1', 'c1')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/dr_w1'), proposalData('dr', 'w1', 'c1')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/missing_w1'), proposalData('missing', 'w1', 'c1')));
  });

  test('3. a client cannot submit a proposal', async () => {
    await assertFails(setDoc(doc(user('c2'), 'proposals/j1_c2'), proposalData('j1', 'c2', 'c1')));
  });

  test('4. an unauthenticated user cannot submit', async () => {
    await assertFails(setDoc(doc(anonDb(), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1')));
  });

  test('5. no duplicate proposals: fixed id, one per worker per job', async () => {
    await assertSucceeds(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { proposedRate: 2000 })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/random123'), proposalData('j1', 'w1', 'c1')));
  });

  test('cannot submit on behalf of another worker, to a different client, or with fake ratings/decisions', async () => {
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w2'), proposalData('j1', 'w2', 'c1')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c2')));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { workerRating: 5 })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { status: 'accepted' })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { createdAt: Timestamp.fromDate(new Date(2020, 0, 1)) })));
    await assertFails(setDoc(doc(user('ws'), 'proposals/j1_ws'), proposalData('j1', 'ws', 'c1')), 'suspended worker');
  });

  test('invalid content is rejected', async () => {
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { coverLetter: 'Hi' })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { proposedRate: 0 })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { rateType: 'barter' })));
    await assertFails(setDoc(doc(user('w1'), 'proposals/j1_w1'), proposalData('j1', 'w1', 'c1', { estimatedDuration: '' })));
  });
});

describe('proposals: changes and reading', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1'));
    await seed('proposals/j1_w2', proposalData('j1', 'w2', 'c1', { workerName: 'Kamran' }));
    await seed('proposals/other_w1', proposalData('other', 'w1', 'c2'));
  });

  test('6. a worker cannot modify another worker\'s proposal', async () => {
    await assertFails(updateDoc(doc(user('w2'), 'proposals/j1_w1'), { proposedRate: 1 }));
    await assertFails(updateDoc(doc(user('w2'), 'proposals/j1_w1'), { status: 'withdrawn' }));
  });

  test('7. ownership and job links cannot change', async () => {
    await assertFails(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { workerId: 'w2' }));
    await assertFails(updateDoc(doc(user('c1'), 'proposals/j1_w1'), { clientId: 'c2' }));
    await assertFails(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { jobId: 'other' }));
  });

  test('8. a worker cannot accept (or reject) their own proposal', async () => {
    await assertFails(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { status: 'accepted' }));
    await assertFails(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { status: 'rejected', closedReason: 'client' }));
  });

  test('withdraw, then re-send while the job is open', async () => {
    await assertSucceeds(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { status: 'withdrawn', withdrawnAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'proposals/j1_w1'), {
      status: 'pending', proposedRate: 2200, resubmittedAt: serverTimestamp(), withdrawnAt: null, updatedAt: serverTimestamp(),
    }));
  });

  test('a withdrawn proposal cannot be accepted; a declined one cannot be re-sent or accepted', async () => {
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1', { status: 'withdrawn' }));
    await assertFails(acceptBatch(user('c1'), { contract: false }).commit());
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1', { status: 'rejected', closedReason: 'client' }));
    await assertFails(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { status: 'pending' }));
    await assertFails(acceptBatch(user('c1'), { contract: false }).commit());
  });

  test('9. a client sees the proposals for their own job, marks viewed, declines', async () => {
    const c1 = user('c1');
    const snap = await assertSucceeds(getDocs(query(collection(c1, 'proposals'), where('jobId', '==', 'j1'), where('clientId', '==', 'c1'))));
    assert.equal(snap.size, 2);
    await assertSucceeds(updateDoc(doc(c1, 'proposals/j1_w1'), { viewedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(c1, 'proposals/j1_w1'), { viewedAt: serverTimestamp() }), 'viewed is set once');
    await assertSucceeds(updateDoc(doc(c1, 'proposals/j1_w2'), { status: 'rejected', closedReason: 'client', decidedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });

  test('10. other clients and workers cannot read someone else\'s proposals', async () => {
    await assertFails(getDoc(doc(user('c2'), 'proposals/j1_w1')));
    await assertFails(getDoc(doc(user('w2'), 'proposals/j1_w1')));
    await assertFails(getDocs(query(collection(user('c2'), 'proposals'), where('jobId', '==', 'j1'))));
    await assertSucceeds(getDocs(query(collection(user('w1'), 'proposals'), where('workerId', '==', 'w1'))));
  });

  test('11. the client accepts an eligible proposal: proposal, job, other proposals and contract together', async () => {
    // Phase 4A: only acceptProposalCall may hire; the client batch is refused.
    await assertFails(acceptBatch(user('c1'), { others: ['w2'] }).commit());
    await seedHired({ others: ['w2'] });
    // The hired worker can now read the job. The other applicant cannot (it
    // names who was hired); they follow it through proposals/{id}.jobStatus.
    await assertSucceeds(getDoc(doc(user('w1'), 'jobs/j1')));
    await assertFails(getDoc(doc(user('w2'), 'jobs/j1')));
    await assertSucceeds(getDoc(doc(user('w2'), 'proposals/j1_w2')));
  });

  test('12. a client cannot accept a proposal for another client\'s job', async () => {
    await assertFails(acceptBatch(user('c2'), { contract: false }).commit());
    const c1 = user('c1');
    const b = writeBatch(c1);
    b.update(doc(c1, 'proposals/other_w1'), { status: 'accepted' });
    await assertFails(b.commit());
  });

  test('13. two proposals can never both be accepted', async () => {
    const c1 = user('c1');
    const both = acceptBatch(c1, { contract: false });
    both.update(doc(c1, 'proposals/j1_w2'), { status: 'accepted', decidedAt: serverTimestamp(), updatedAt: serverTimestamp() });
    await assertFails(both.commit());
    await assertFails(acceptBatch(user('c1'), { contract: false }).commit(), 'hiring is server-only');
    await seedHired();
    await assertFails(acceptBatch(user('c1'), { workerId: 'w2', contract: false }).commit());
  });

  test('accepting without assigning the job, or assigning without accepting, is refused', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'proposals/j1_w1'), { status: 'accepted' }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
  });

  test('14. proposal counts cannot be changed by users', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { totalProposals: 5 }));
    await assertFails(updateDoc(doc(user('w1'), 'jobs/j1'), { totalProposals: 3 }));
    await assertSucceeds(updateDoc(doc(admin().firestore(), 'jobs/j1'), { totalProposals: 2 }), 'trusted (Admin SDK / function)');
  });

  test('only staff delete proposals', async () => {
    await assertFails(deleteDoc(doc(user('w1'), 'proposals/j1_w1')));
    await assertFails(deleteDoc(doc(user('c1'), 'proposals/j1_w1')));
  });
});

describe('contracts', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1'));
  });

  test('a worker cannot create a contract; a client cannot without an accepted proposal', async () => {
    await assertFails(setDoc(doc(user('w1'), 'contracts/x'), { jobId: 'j1', proposalId: 'j1_w1', clientId: 'c1', workerId: 'w1', paymentStatus: 'unpaid' }));
    await assertFails(setDoc(doc(user('c1'), 'contracts/x'), { jobId: 'j1', proposalId: 'j1_w1', clientId: 'c1', workerId: 'w1', paymentStatus: 'unpaid' }));
  });

  test('direct hire (job + contract together) still works', async () => {
    const db = user('c1');
    const b = writeBatch(db);
    b.set(doc(db, 'jobs/dh'), jobData('c1', { title: 'Direct Hire: Electrician', status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
    b.set(doc(db, 'contracts/dh1'), { jobId: 'dh', proposalId: 'direct_hire', clientId: 'c1', workerId: 'w1', paymentStatus: 'unpaid', status: 'pending' });
    await assertSucceeds(b.commit());
  });

  test('money and payment fields cannot be edited by the parties', async () => {
    await seed('contracts/k1', { jobId: 'j1', proposalId: 'j1_w1', clientId: 'c1', workerId: 'w1', totalAmount: 2500, paymentStatus: 'unpaid', status: 'active' });
    await assertFails(updateDoc(doc(user('w1'), 'contracts/k1'), { totalAmount: 99999 }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/k1'), { paymentStatus: 'paid' }));
    // Phase 4A: status is server-only; a worker can never complete their own contract.
    await assertFails(updateDoc(doc(user('w1'), 'contracts/k1'), { status: 'completed', updatedAt: serverTimestamp() }));
  });
});

describe('chat (Phase 4B: conversations are opened by the trusted function)', () => {
  const chat = (jobId, a, b, extra = {}) => ({
    participantIds: [a, b], participantNames: { [a]: 'A', [b]: 'B' }, participantPhotos: { [a]: null, [b]: null },
    lastMessage: '', lastMessageSenderId: '', lastMessageType: 'none', lastMessageAt: serverTimestamp(),
    unreadCount: { [a]: 0, [b]: 1 }, lastReadAt: {},
    ...(jobId ? { relatedJobId: jobId, relatedJobTitle: 'Fix kitchen wiring' } : {}), ...extra,
  });
  const message = (chatId, senderId, extra = {}) => ({
    chatId, senderId, senderName: 'A', content: 'Hello, is the job still open?', type: 'text', isRead: false, createdAt: serverTimestamp(), ...extra,
  });
  const send = (uid, id, data, chatId = 'j1_w1') => setDoc(doc(user(uid), `chats/${chatId}/messages/${id}`), data);

  beforeEach(async () => {
    await seedMarket();
    await seed('chats/j1_w1', chat('j1', 'w1', 'c1'));
    await seed('chats/j1_w1/messages/seed_msg_0001', message('j1_w1', 'w1', { createdAt: Timestamp.now() }));
  });

  test('16. existing participants keep using chat', async () => {
    const c1 = user('c1');
    await assertSucceeds(getDoc(doc(c1, 'chats/j1_w1')));
    await assertSucceeds(getDocs(query(collection(c1, 'chats'), where('participantIds', 'array-contains', 'c1'))));
    await assertSucceeds(getDocs(query(collection(c1, 'chats/j1_w1/messages'), orderBy('createdAt', 'desc'), limit(30))));
    await assertSucceeds(send('c1', 'msg_c1_000001', message('j1_w1', 'c1')));
    await assertSucceeds(updateDoc(doc(c1, 'chats/j1_w1'), { 'lastReadAt.c1': serverTimestamp(), 'unreadCount.c1': 0 }), 'mark read');
    await assertSucceeds(updateDoc(doc(c1, 'chats/j1_w1/messages/seed_msg_0001'), { isRead: true }));
  });

  test('conversations are created only by the trusted function, never directly', async () => {
    await assertFails(setDoc(doc(user('w2'), 'chats/j1_w2'), chat('j1', 'w2', 'c1')), 'even about a public open job');
    await seed('proposals/closed1_w2', proposalData('closed1', 'w2', 'c1'));
    await assertFails(setDoc(doc(user('c1'), 'chats/closed1_w2'), chat('closed1', 'c1', 'w2')), 'even with a proposal');
    await assertFails(setDoc(doc(user('c2'), 'chats/direct_c2_w2'), chat(null, 'c2', 'w2')), 'direct chats too');
    await assertFails(setDoc(doc(user('c1'), 'chats/j1_w1'), chat('j1', 'c1', 'w1')), 'no overwriting an existing chat');
    await assertSucceeds(setDoc(doc(admin().firestore(), 'chats/direct_c2_w2'), chat(null, 'c2', 'w2')), 'staff / Admin SDK');
  });

  test('15. unrelated users cannot read job chats', async () => {
    await assertFails(getDoc(doc(user('c2'), 'chats/j1_w1')));
    await assertFails(getDocs(collection(user('c2'), 'chats/j1_w1/messages')));
    await assertFails(getDocs(collection(user('c2'), 'chats')));
    await assertFails(getDoc(doc(anonDb(), 'chats/j1_w1')));
  });

  test('members cannot edit previews, unread counts or participants; only mark their own read, at server time', async () => {
    const c1 = user('c1');
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { lastMessage: 'Forged', lastMessageSenderId: 'c1', lastMessageAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { 'unreadCount.w1': 5 }), "the other person's count");
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { 'unreadCount.c1': 0 }), 'reset without a read marker');
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { 'lastReadAt.w1': serverTimestamp(), 'unreadCount.w1': 0 }), "the other person's marker");
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { 'lastReadAt.c1': Timestamp.fromMillis(0), 'unreadCount.c1': 0 }), 'client-chosen time');
    await assertFails(updateDoc(doc(c1, 'chats/j1_w1'), { 'lastReadAt.c1': serverTimestamp(), 'unreadCount.c1': 3 }));
    await assertFails(updateDoc(doc(user('c2'), 'chats/j1_w1'), { 'lastReadAt.c2': serverTimestamp(), 'unreadCount.c2': 0 }), 'not a member');
    await assertFails(updateDoc(doc(user('w1'), 'chats/j1_w1'), { participantIds: ['w1', 'c1', 'c2'] }));
    await assertFails(updateDoc(doc(user('c2'), 'chats/j1_w1'), { participantIds: ['c2', 'c1'] }));
    await assertFails(updateDoc(doc(user('w1'), 'chats/j1_w1'), { relatedJobId: 'other' }));
    await assertFails(deleteDoc(doc(c1, 'chats/j1_w1')));
  });

  test('messages: sender, server time, read flag and content are checked; a message id is used once', async () => {
    await assertFails(send('c1', 'msg_000000a1', message('j1_w1', 'w1')), 'spoofed sender');
    await assertFails(send('c2', 'msg_000000a2', message('j1_w1', 'c2')), 'not a member');
    await assertFails(send('c1', 'msg_000000a3', message('j1_w1', 'c1', { createdAt: Timestamp.fromMillis(Date.now() + 86400000) })), 'client time');
    await assertFails(send('c1', 'msg_000000a4', message('j1_w1', 'c1', { isRead: true })));
    await assertFails(send('c1', 'msg_000000a5', message('j1_w1', 'c1', { unreadCount: 0 })), 'unknown field');
    await assertFails(send('c1', 'msg_000000a6', message('j1_w1', 'c1', { content: '   ' })), 'blank');
    await assertFails(send('c1', 'msg_000000a7', message('j1_w1', 'c1', { type: 'system' })), 'system messages are not user-written');
    await assertFails(send('c1', 'msg_000000a8', message('j1_w1', 'c1', { content: 'x'.repeat(5001) })));
    await assertFails(send('c1', 'msg_000000a9', message('other_chat', 'c1')), 'chatId must match');
    await assertFails(send('c1', 'm3', message('j1_w1', 'c1')), 'ids are 8–64 safe characters');
    await assertSucceeds(send('c1', 'msg_000000b1', message('j1_w1', 'c1')));
    await assertFails(send('c1', 'msg_000000b1', message('j1_w1', 'c1', { content: 'Second copy' })), 'retry cannot overwrite or duplicate');
    await assertFails(updateDoc(doc(user('w1'), 'chats/j1_w1/messages/seed_msg_0001'), { content: 'edited' }));
    await assertFails(updateDoc(doc(user('w1'), 'chats/j1_w1/messages/seed_msg_0001'), { isRead: true }), 'senders do not mark their own');
    await assertFails(deleteDoc(doc(user('w1'), 'chats/j1_w1/messages/seed_msg_0001')));
  });

  test("photo messages point only at the sender's own folder for that message", async () => {
    const id = 'msg_photo_001';
    const photo = (paths, extra = {}) => message('j1_w1', 'c1', { type: 'image', content: '', attachments: paths, ...extra });
    await assertSucceeds(send('c1', id, photo([`chats/j1_w1/c1/${id}/p1.jpg`, `chats/j1_w1/c1/${id}/p2.png`])));
    const bad = [
      [`chats/j1_w1/w1/msg_photo_002/p1.jpg`],          // someone else's folder
      [`chats/j1_w1/c1/msg_other_01/p1.jpg`],           // another message
      [`chats/other/c1/msg_photo_002/p1.jpg`],          // another chat
      [`chats/j1_w1/c1/msg_photo_002/p1.pdf`],          // not a photo
      [`chats/j1_w1/c1/msg_photo_002/../x.jpg`],        // path tricks
      [],
      ['a', 'b', 'c', 'd'].map((n) => `chats/j1_w1/c1/msg_photo_002/${n}.jpg`),
    ];
    for (const paths of bad) await assertFails(send('c1', 'msg_photo_002', photo(paths)), JSON.stringify(paths));
    await assertFails(send('c1', 'msg_photo_003', message('j1_w1', 'c1', { attachments: [`chats/j1_w1/c1/msg_photo_003/p.jpg`] })), 'text messages carry no attachments');
  });

  test('no messages to suspended or deleted accounts; suspended accounts cannot post', async () => {
    await seed('chats/x_ws', chat(null, 'c1', 'ws'));
    await assertFails(send('c1', 'msg_000000c1', message('x_ws', 'c1'), 'x_ws'), 'recipient suspended');
    await seed('chats/x_cs', chat(null, 'cs', 'w1'));
    await assertFails(send('cs', 'msg_000000c2', message('x_cs', 'cs'), 'x_cs'), 'sender suspended');
    await seed('chats/x_gone', chat(null, 'c1', 'gone'));
    await assertFails(send('c1', 'msg_000000c3', message('x_gone', 'c1'), 'x_gone'), 'recipient deleted');
  });

  test('message, revision and progress notifications cannot be forged', async () => {
    const n = (type) => ({ userId: 'w1', title: 'New message from Ayesha', body: 'Hi', type, isRead: false, createdAt: serverTimestamp() });
    for (const type of ['message', 'revision_requested', 'progress_update']) {
      await assertFails(setDoc(doc(user('c1'), `notifications/forged_${type}`), n(type)), type);
    }
    await assertSucceeds(setDoc(doc(user('c1'), 'notifications/other'), n('proposal')), 'unchanged for older flows (see report)');
  });
});

// ── Phase 3B privacy remediation: public/private profiles, live location,
// hired-worker identity ─────────────────────────────────────────────────

const privateProfile = (uid, role, extra = {}) => ({
  ...baseProfile(uid, role), phoneNumber: '+923001234567', address: 'House 5, Gulberg III',
  fcmToken: 'token-x', city: 'Lahore', ...extra,
});
const publicProfile = (uid, role, extra = {}) => ({
  uid, role, displayName: 'Test', city: 'Lahore', isActive: true, isEmailVerified: true, ...extra,
});

describe('profiles: private account vs public profile', () => {
  beforeEach(async () => {
    await seed('users/c1', privateProfile('c1', 'client'));
    await seed('users/w1', privateProfile('w1', 'worker', { workerProfile: { headline: 'Electrician', totalEarnings: 90000 } }));
    await seed('users/w2', privateProfile('w2', 'worker'));
    await seed('publicProfiles/w1', publicProfile('w1', 'worker', {
      geohash: 'ttsg2', workerProfile: { headline: 'Electrician' },
    }));
    await seed('publicProfiles/c1', publicProfile('c1', 'client'));
  });

  test('owners read their own full account', async () => {
    const snap = await assertSucceeds(getDoc(doc(user('w1'), 'users/w1')));
    assert.equal(snap.data().phoneNumber, '+923001234567');
  });

  test('other users cannot read someone else\'s account (phone, address, token)', async () => {
    await assertFails(getDoc(doc(user('c1'), 'users/w1')));
    await assertFails(getDoc(doc(user('w2'), 'users/w1')));
    await assertFails(getDoc(doc(user('w1'), 'users/c1')));
    await assertFails(getDoc(doc(anonDb(), 'users/w1')));
  });

  test('nobody but staff can list or search accounts', async () => {
    await assertFails(getDocs(query(collection(user('c1'), 'users'), where('role', '==', 'worker'))));
    await assertFails(getDocs(collection(user('c1'), 'users')));
    await assertSucceeds(getDocs(query(collection(admin().firestore(), 'users'), where('role', '==', 'worker'))));
  });

  test('staff (trusted admin claim) can read any account', async () => {
    await assertSucceeds(getDoc(doc(admin().firestore(), 'users/w1')));
  });

  test('any signed-in user reads public profiles, including discovery queries', async () => {
    const snap = await assertSucceeds(getDoc(doc(user('c1'), 'publicProfiles/w1')));
    assert.equal(snap.data().phoneNumber, undefined);
    await assertSucceeds(getDoc(doc(user('w1'), 'publicProfiles/c1')));
    await assertSucceeds(getDocs(query(collection(user('c1'), 'publicProfiles'), where('role', '==', 'worker'))));
    await assertSucceeds(getDocs(query(collection(user('c1'), 'publicProfiles'),
      where('role', '==', 'worker'), where('geohash', '>=', 'tts'), where('geohash', '<=', 'tts~'))));
    await assertFails(getDoc(doc(anonDb(), 'publicProfiles/w1')));
  });

  test('public profiles cannot be written by anyone but the trusted function', async () => {
    await assertFails(setDoc(doc(user('w1'), 'publicProfiles/w1'), publicProfile('w1', 'worker', { phoneNumber: '+923001234567' })));
    await assertFails(updateDoc(doc(user('w1'), 'publicProfiles/w1'), { displayName: 'Changed' }));
    await assertFails(updateDoc(doc(user('w1'), 'publicProfiles/w1'), { 'workerProfile.isVerified': true }));
    await assertFails(setDoc(doc(user('c1'), 'publicProfiles/w1'), publicProfile('w1', 'worker')));
    await assertFails(deleteDoc(doc(user('w1'), 'publicProfiles/w1')));
  });

  test('owners still update their own account as before', async () => {
    await assertSucceeds(updateDoc(doc(user('w1'), 'users/w1'), { displayName: 'Bilal A.', fcmToken: 'token-y' }));
  });
});

describe('live location: only the clients of the worker\'s active jobs', () => {
  beforeEach(async () => {
    await seedUsers();
    await seed('liveLocations/w1', {
      workerId: 'w1', viewerIds: ['c1'], isLocationSharing: true,
      location: null, heading: null, locationUpdatedAt: null,
    });
  });

  test('the worker and the client of their active job can read it', async () => {
    await assertSucceeds(getDoc(doc(user('w1'), 'liveLocations/w1')));
    await assertSucceeds(getDoc(doc(user('c1'), 'liveLocations/w1')));
    await assertSucceeds(getDoc(doc(admin().firestore(), 'liveLocations/w1')));
  });

  test('other clients, other workers and signed-out users cannot', async () => {
    await assertFails(getDoc(doc(user('c2'), 'liveLocations/w1')));
    await assertFails(getDoc(doc(user('w2'), 'liveLocations/w1')));
    await assertFails(getDoc(doc(anonDb(), 'liveLocations/w1')));
    await assertFails(getDoc(doc(user('c2'), 'liveLocations/missing')));
  });

  test('nobody can add themselves as a viewer or write a position', async () => {
    await assertFails(updateDoc(doc(user('c2'), 'liveLocations/w1'), { viewerIds: ['c1', 'c2'] }));
    await assertFails(updateDoc(doc(user('w1'), 'liveLocations/w1'), { viewerIds: ['c1', 'c2'] }));
    await assertFails(setDoc(doc(user('w2'), 'liveLocations/w2'), { workerId: 'w2', viewerIds: ['c2'] }));
  });

  test('a worker\'s full account is not a back door to their live position', async () => {
    await assertFails(getDoc(doc(user('c1'), 'users/w1')));
  });
});

describe('hired worker identity', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1'));
    await seed('proposals/j1_w2', proposalData('j1', 'w2', 'c1', { workerName: 'Kamran' }));
  });

  test('after a hire only the owner, the hired worker and staff can read the job (and its selectedWorkerName)', async () => {
    await seedHired({ others: ['w2'] });
    const owner = await assertSucceeds(getDoc(doc(user('c1'), 'jobs/j1')));
    assert.equal(owner.data().selectedWorkerName, 'Bilal');
    const hired = await assertSucceeds(getDoc(doc(user('w1'), 'jobs/j1')));
    assert.equal(hired.data().selectedWorkerId, 'w1');
    await assertSucceeds(getDoc(doc(admin().firestore(), 'jobs/j1')));
    await assertFails(getDoc(doc(user('w2'), 'jobs/j1')), 'unsuccessful applicant');
    await assertFails(getDoc(doc(user('c2'), 'jobs/j1')));
    await assertFails(getDocs(query(collection(user('w2'), 'jobs'), where('selectedWorkerId', '==', 'w1'))));
  });

  test('the hired worker and the owner can read the contract; the other applicant cannot', async () => {
    await seedHired({ others: ['w2'] });
    await assertSucceeds(getDoc(doc(user('c1'), 'contracts/j1_w1')));
    await assertSucceeds(getDoc(doc(user('w1'), 'contracts/j1_w1')));
    await assertFails(getDoc(doc(user('w2'), 'contracts/j1_w1')));
  });

  test('applicants follow the job through the status copied to their proposal, which they cannot forge', async () => {
    await seed('proposals/j1_w2', proposalData('j1', 'w2', 'c1', { status: 'rejected', closedReason: 'filled', jobStatus: 'assigned' }));
    const mine = await assertSucceeds(getDoc(doc(user('w2'), 'proposals/j1_w2')));
    assert.equal(mine.data().jobStatus, 'assigned');
    await assertFails(updateDoc(doc(user('w2'), 'proposals/j1_w2'), { jobStatus: 'open' }));
    await assertFails(updateDoc(doc(user('c1'), 'proposals/j1_w1'), { jobStatus: 'completed' }));
    await assertFails(setDoc(doc(user('w1'), 'proposals/other_w1'), proposalData('other', 'w1', 'c2', { jobStatus: 'open' })));
  });

  test('withdraw and re-send still work on a proposal that carries a copied job status', async () => {
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1', { jobStatus: 'open' }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'proposals/j1_w1'), { status: 'withdrawn', withdrawnAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'proposals/j1_w1'), {
      status: 'pending', resubmittedAt: serverTimestamp(), updatedAt: serverTimestamp(), withdrawnAt: deleteField(),
    }));
  });

  test('a public open job is still readable by any active user (no hired worker on it)', async () => {
    const open = await assertSucceeds(getDoc(doc(user('w2'), 'jobs/j1')));
    assert.equal(open.data().selectedWorkerId, null);
  });
});

// ── Phase 4A: contracts and the work lifecycle ────────────────────────────
// Creating proposal contracts and every status change run in the trusted
// functions (functions/test/contracts.test.js covers their logic). These
// tests prove users cannot do any of it directly.

const contractData = (extra = {}) => ({
  jobId: 'j1', proposalId: 'j1_w1', clientId: 'c1', workerId: 'w1', clientName: 'Ayesha', workerName: 'Bilal',
  agreedRate: 2500, rateType: 'fixed', totalAmount: 2500, commissionRate: 0.1, commissionAmount: 250,
  workerEarnings: 2250, paymentStatus: 'unpaid', status: 'active', clientReviewed: false, workerReviewed: false,
  workStartedAt: null, submittedAt: null, completedAt: null, ...extra,
});

describe('Phase 4A contracts: access and protected fields', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1', { status: 'accepted' }));
    await seed('jobs/j1', jobData('c1', { status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
    await seed('contracts/j1_w1', contractData());
  });

  test('3. only the two participants (and staff) read a contract', async () => {
    await assertSucceeds(getDoc(doc(user('c1'), 'contracts/j1_w1')));
    await assertSucceeds(getDoc(doc(user('w1'), 'contracts/j1_w1')));
    await assertSucceeds(getDoc(doc(admin().firestore(), 'contracts/j1_w1')));
    await assertSucceeds(getDocs(query(collection(user('c1'), 'contracts'), where('clientId', '==', 'c1'))));
    await assertSucceeds(getDocs(query(collection(user('w1'), 'contracts'), where('workerId', '==', 'w1'), where('jobId', '==', 'j1'))));
  });

  test('4. unrelated users cannot read contracts or list them', async () => {
    await assertFails(getDoc(doc(user('c2'), 'contracts/j1_w1')));
    await assertFails(getDoc(doc(user('w2'), 'contracts/j1_w1')));
    await assertFails(getDoc(doc(anonDb(), 'contracts/j1_w1')));
    await assertFails(getDocs(query(collection(user('w2'), 'contracts'), where('jobId', '==', 'j1'))));
    await assertFails(getDocs(collection(user('c2'), 'contracts')));
  });

  test('1–2. clients cannot create proposal contracts themselves (only the function, once)', async () => {
    await assertFails(setDoc(doc(user('c1'), 'contracts/j1_w1b'), contractData({ proposalId: 'j1_w1' })));
    await assertFails(setDoc(doc(user('c1'), 'contracts/j1_w1'), contractData()), 'no overwrite of the existing contract');
    await assertFails(setDoc(doc(user('w1'), 'contracts/self'), contractData({ proposalId: 'direct_hire', status: 'pending' })), 'a worker cannot create a contract for themselves');
  });

  test('5–6. the worker cannot start or submit by writing the contract', async () => {
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { workStartedAt: serverTimestamp(), updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { submittedAt: serverTimestamp(), submission: { note: 'done', attachments: [] } }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { workStartedAt: serverTimestamp() }), 'the client cannot start it either');
  });

  test('7–8. nobody completes a contract by writing it; a worker can never self-confirm', async () => {
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now(), submittedAt: Timestamp.now() }));
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { status: 'completed', completedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { status: 'completed', completedAt: serverTimestamp() }), 'client confirms through the function');
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { completedAt: Timestamp.now() }), 'no fabricated timestamps');
  });

  test('9–10. prices, ownership and status cannot be changed by either party', async () => {
    for (const who of ['c1', 'w1']) {
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { agreedRate: 1 }));
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { totalAmount: 1, workerEarnings: 1 }));
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { clientId: 'c2' }));
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { workerId: 'w2' }));
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { status: 'cancelled' }));
      await assertFails(updateDoc(doc(user(who), 'contracts/j1_w1'), { serviceAddress: 'Somewhere' }), 'address is shared through the function');
    }
    await assertFails(deleteDoc(doc(user('c1'), 'contracts/j1_w1')));
  });

  test('11. job status cannot be moved out of step with the contract', async () => {
    await assertFails(updateDoc(doc(user('w1'), 'jobs/j1'), { status: 'in_progress', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'completed', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('c1'), 'jobs/j1'), { status: 'cancelled', updatedAt: serverTimestamp() }));
  });

  test('reviews: after completion each party sets only their own flag, once', async () => {
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { clientReviewed: true }), 'not completed yet');
    await seed('contracts/j1_w1', contractData({ status: 'completed', completedAt: Timestamp.now() }));
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { clientReviewed: true }), 'not your flag');
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { clientReviewed: true, agreedRate: 1 }));
    await assertSucceeds(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { clientReviewed: true }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { workerReviewed: true }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { clientReviewed: false }), 'cannot undo');
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { status: 'active' }), 'completion is final');
  });

  test('booking requests: created pending only, with no lifecycle data, for the client\'s own job', async () => {
    const make = (extra) => {
      const db = user('c1');
      const b = writeBatch(db);
      b.set(doc(db, 'jobs/dh'), jobData('c1', { title: 'Direct Hire: Electrician', status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
      b.set(doc(db, 'contracts/dh1'), { jobId: 'dh', proposalId: 'direct_hire', clientId: 'c1', workerId: 'w1', paymentStatus: 'unpaid', status: 'pending', ...extra });
      return b.commit();
    };
    await assertFails(make({ status: 'active' }));
    await assertFails(make({ workStartedAt: Timestamp.now() }));
    await assertFails(make({ completedAt: Timestamp.now() }));
    await assertFails(make({ paymentStatus: 'released' }));
    await assertSucceeds(make({}));
  });
});

describe('Phase 4A: contract-linked chat', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('proposals/j1_w1', proposalData('j1', 'w1', 'c1', { status: 'accepted' }));
    await seed('proposals/j1_w2', proposalData('j1', 'w2', 'c1', { status: 'rejected', closedReason: 'filled' }));
    await seed('jobs/j1', jobData('c1', { status: 'assigned', selectedWorkerId: 'w1', selectedWorkerName: 'Bilal' }));
    await seed('contracts/j1_w1', contractData());
    await seed('chats/j1_w1', {
      participantIds: ['c1', 'w1'], participantNames: { c1: 'Ayesha', w1: 'Bilal' }, relatedJobId: 'j1',
      relatedJobTitle: 'Fix kitchen wiring', lastMessage: 'Proposal accepted.', lastMessageSenderId: 'c1', unreadCount: { c1: 0, w1: 1 },
    });
  });

  test('12. the client and hired worker use it; unsuccessful applicants and others cannot', async () => {
    await assertSucceeds(getDoc(doc(user('c1'), 'chats/j1_w1')));
    await assertSucceeds(getDoc(doc(user('w1'), 'chats/j1_w1')));
    for (const who of ['w2', 'c2']) {
      await assertFails(getDoc(doc(user(who), 'chats/j1_w1')));
      await assertFails(getDocs(collection(user(who), 'chats/j1_w1/messages')));
      await assertFails(setDoc(doc(user(who), 'chats/j1_w1/messages/msg_join_0001'), {
        chatId: 'j1_w1', senderId: who, content: 'Can I join?', type: 'text', isRead: false, createdAt: serverTimestamp(),
      }));
      await assertFails(updateDoc(doc(user(who), 'chats/j1_w1'), { participantIds: ['c1', 'w1', who] }));
    }
    await assertSucceeds(setDoc(doc(user('w1'), 'chats/j1_w1/messages/msg_onway_001'), {
      chatId: 'j1_w1', senderId: 'w1', senderName: 'Bilal', content: 'On my way.', type: 'text', isRead: false, createdAt: serverTimestamp(),
    }));
  });
});

describe('Phase 4A storage: work evidence', () => {
  const jpg = new Uint8Array([255, 216, 255, 224, 0, 16]);
  const meta = { contentType: 'image/jpeg' };
  const put = (uid, name = 'a.jpg', contentType = 'image/jpeg') =>
    uploadBytes(ref(env.authenticatedContext(uid).storage(), `contracts/j1_w1/evidence/${name}`), jpg, { contentType });

  beforeEach(async () => {
    await seedUsers();
  });

  test('only the hired worker uploads, and only while the work is in progress', async () => {
    await seed('contracts/j1_w1', contractData());
    await assertFails(put('w1'), 'not started yet');
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now() }));
    await assertSucceeds(put('w1'));
    await assertFails(put('c1'), 'the client does not upload evidence');
    await assertFails(put('w2'), 'another worker');
    await assertFails(put('w1', 'doc.pdf', 'application/pdf'), 'images only');
    await assertFails(put('w1', '../escape.jpg'));
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now(), submittedAt: Timestamp.now() }));
    await assertFails(put('w1', 'late.jpg'), 'no changes after submission');
  });

  test('evidence is visible to the two parties and staff only, and is kept', async () => {
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now() }));
    // Own file name per test: the Storage emulator keeps files across tests.
    await assertSucceeds(put('w1', 'visible.jpg'));
    const path = 'contracts/j1_w1/evidence/visible.jpg';
    await assertSucceeds(getBytes(ref(env.authenticatedContext('c1').storage(), path)));
    await assertSucceeds(getBytes(ref(env.authenticatedContext('w1').storage(), path)));
    await assertFails(getBytes(ref(env.authenticatedContext('w2').storage(), path)));
    await assertFails(getBytes(ref(env.authenticatedContext('c2').storage(), path)));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), path)));
    await assertFails(deleteObject(ref(env.authenticatedContext('w1').storage(), path)), 'part of the record');
    void meta;
  });
});

// ── Phase 4B: live location, progress updates, submission history ────────
// Live location is written by the worker from the device; everything else is
// written only by the trusted functions (functions/test/contracts.test.js).

describe('Phase 4B: live location on the contract', () => {
  const live = (uid) => doc(user(uid), 'contracts/j1_w1/live/location');
  const loc = (extra = {}) => ({
    workerId: 'w1', position: new GeoPoint(31.52, 74.35), accuracy: 12,
    updatedAt: serverTimestamp(), startedAt: serverTimestamp(), ...extra,
  });

  beforeEach(async () => {
    await seedMarket();
    await seed('contracts/j1_w1', contractData());
  });

  test('only the hired worker shares, at server time, while the contract is active', async () => {
    await assertSucceeds(setDoc(live('w1'), loc()), 'on the way (not started yet)');
    await assertSucceeds(updateDoc(live('w1'), { position: new GeoPoint(31.53, 74.36), accuracy: 8, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(live('w1'), { updatedAt: Timestamp.fromMillis(Date.now() + 3600000) }), 'client-chosen time would look live');
    await assertFails(updateDoc(live('w1'), { position: new GeoPoint(31.5, 74.3) }), 'every update carries a fresh server time');
    await assertFails(updateDoc(live('w1'), { startedAt: Timestamp.fromMillis(0), updatedAt: serverTimestamp() }), 'no made-up start time');
    await assertSucceeds(setDoc(live('w1'), loc()), 'sharing again later starts a new session (server time)');
    await assertFails(setDoc(live('c1'), loc({ workerId: 'c1' })), 'the client');
    await assertFails(setDoc(live('w2'), loc({ workerId: 'w2' })), 'another worker');
    await assertFails(setDoc(doc(user('w1'), 'contracts/j1_w1/live/other'), loc()), 'one document only');
    await assertFails(setDoc(live('w1'), loc({ battery: 80 })), 'unknown field');
    await assertFails(setDoc(live('w1'), loc({ accuracy: -1 })));
    await assertFails(setDoc(live('w1'), loc({ position: 'Gulberg' })));
  });

  test('sharing is refused once work is waiting for review, completed or cancelled; allowed again after a revision', async () => {
    const at = async (extra) => {
      await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now(), ...extra }));
      return setDoc(live('w1'), loc());
    };
    await assertFails(at({ submittedAt: Timestamp.now() }), 'Phase 4A submission, no counters');
    await assertFails(at({ submittedAt: Timestamp.now(), submissionCount: 1, revisionCount: 0 }));
    await assertSucceeds(at({ submittedAt: Timestamp.now(), submissionCount: 1, revisionCount: 1 }), 'sent back for changes');
    await assertFails(at({ status: 'completed', completedAt: Timestamp.now() }));
    await assertFails(at({ status: 'cancelled' }));
    await assertFails(at({ status: 'pending' }));
    await seed('users/w1', { ...baseProfile('w1', 'worker'), isActive: false });
    await assertFails(at({}), 'suspended worker');
  });

  test('Navigation phase 8: direction and speed are optional, within real ranges, and can be cleared', async () => {
    await assertSucceeds(setDoc(live('w1'), loc({ heading: 92.5, speed: 9.7 })));
    await assertSucceeds(updateDoc(live('w1'), { position: new GeoPoint(31.53, 74.36), heading: 0, speed: 0, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(live('w1'), { position: new GeoPoint(31.53, 74.37), heading: deleteField(), updatedAt: serverTimestamp() }),
      'standing still: no direction');
    for (const [extra, why] of [
      [{ heading: 361 }, 'heading over 360'],
      [{ heading: -1 }, 'negative heading'],
      [{ heading: 'north' }, 'not a number'],
      [{ speed: -0.1 }, 'negative speed'],
      [{ speed: 150 }, 'impossible speed'],
      [{ speed: '9' }, 'not a number'],
    ]) {
      await assertFails(setDoc(live('w1'), loc(extra)), why);
    }
    await assertFails(setDoc(live('c1'), loc({ workerId: 'c1', heading: 10, speed: 1 })), 'still only the hired worker');
  });

  test('only the two parties and staff read it; the worker stops by deleting it', async () => {
    await assertSucceeds(setDoc(live('w1'), loc()));
    await assertSucceeds(getDoc(live('c1')));
    await assertSucceeds(getDoc(live('w1')));
    await assertSucceeds(getDoc(doc(admin().firestore(), 'contracts/j1_w1/live/location')));
    for (const who of ['c2', 'w2']) await assertFails(getDoc(live(who)), who);
    await assertFails(getDoc(doc(anonDb(), 'contracts/j1_w1/live/location')));
    await assertFails(deleteDoc(live('c1')), 'the client cannot stop it');
    await assertSucceeds(deleteDoc(live('w1')));
  });
});

describe('Phase 4B fix: GeoPoint validation', () => {
  beforeEach(seedUsers);

  test('a valid GeoPoint can be saved as a location (the helper used to refuse every point)', async () => {
    await assertSucceeds(updateDoc(doc(user('w1'), 'users/w1'), { location: new GeoPoint(31.52, 74.35) }));
    await assertSucceeds(updateDoc(doc(user('w1'), 'users/w1'), { location: null }));
    await assertFails(updateDoc(doc(user('w1'), 'users/w1'), { location: { latitude: 31.5, longitude: 74.3 } }), 'a map is not a point');
    await assertFails(updateDoc(doc(user('w1'), 'users/w1'), { location: 'Lahore' }));
  });
});

describe('Phase 4B: progress updates and submission history', () => {
  beforeEach(async () => {
    await seedMarket();
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now() }));
    await seed('contracts/j1_w1/updates/req_00000001', { note: 'Bought the parts.', authorId: 'w1', authorRole: 'worker', createdAt: Timestamp.now() });
    await seed('contracts/j1_w1/submissions/1', { number: 1, note: 'Sockets replaced.', attachments: [], submittedAt: Timestamp.now() });
  });

  test('the two parties read them; others cannot', async () => {
    for (const who of ['c1', 'w1']) {
      await assertSucceeds(getDocs(query(collection(user(who), 'contracts/j1_w1/updates'), orderBy('createdAt', 'desc'))));
      await assertSucceeds(getDocs(collection(user(who), 'contracts/j1_w1/submissions')));
    }
    for (const who of ['c2', 'w2']) {
      await assertFails(getDocs(collection(user(who), 'contracts/j1_w1/updates')));
      await assertFails(getDoc(doc(user(who), 'contracts/j1_w1/submissions/1')));
    }
  });

  test('nobody writes them directly, and the revision counters are server-only', async () => {
    await assertFails(setDoc(doc(user('w1'), 'contracts/j1_w1/updates/req_00000002'), { note: 'Done!', authorId: 'w1', createdAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1/updates/req_00000001'), { note: 'Edited' }));
    await assertFails(setDoc(doc(user('w1'), 'contracts/j1_w1/submissions/2'), { number: 2, note: 'Sneaky resubmission' }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1/submissions/1'), { revisionNote: 'Fix it' }));
    await assertFails(updateDoc(doc(user('c1'), 'contracts/j1_w1'), { revisionCount: 1, revisionRequestedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(user('w1'), 'contracts/j1_w1'), { submissionCount: 1, submittedAt: serverTimestamp() }));
  });
});

describe('Phase 4B storage: chat photos and evidence after a revision', () => {
  const jpg = new Uint8Array([255, 216, 255, 224, 0, 16]);
  const put = (uid, path, contentType = 'image/jpeg') =>
    uploadBytes(ref(env.authenticatedContext(uid).storage(), path), jpg, { contentType });
  const photo = 'chats/j1_w1/c1/msg_photo_001/p1.jpg';

  beforeEach(async () => {
    await seedUsers();
    await seed('chats/j1_w1', { participantIds: ['c1', 'w1'], participantNames: { c1: 'A', w1: 'B' } });
  });

  test("members upload photos only into their own folder; images only", async () => {
    await assertSucceeds(put('c1', photo));
    await assertSucceeds(put('w1', 'chats/j1_w1/w1/msg_photo_002/p1.png', 'image/png'));
    await assertFails(put('c1', 'chats/j1_w1/w1/msg_photo_003/p1.jpg'), "someone else's folder");
    await assertFails(put('c2', 'chats/j1_w1/c2/msg_photo_004/p1.jpg'), 'not a member');
    await assertFails(put('c1', 'chats/j1_w1/c1/msg_photo_005/doc.pdf', 'application/pdf'));
    await assertFails(put('c1', 'chats/j1_w1/c1/msg_photo_006/anim.jpg', 'image/gif'), 'jpeg, png or webp');
    await assertFails(put('c1', 'chats/j1_w1/c1/m1/p1.jpg'), 'message id format');
    await assertFails(put('c1', 'chats/missing/c1/msg_photo_007/p1.jpg'), 'no such chat');
  });

  test('only the two members and staff can read them; they are kept', async () => {
    const photo = 'chats/j1_w1/c1/msg_photo_010/p1.jpg'; // own name: the emulator keeps files across tests
    await assertSucceeds(put('c1', photo));
    await assertSucceeds(getBytes(ref(env.authenticatedContext('w1').storage(), photo)));
    await assertSucceeds(getBytes(ref(env.authenticatedContext('c1').storage(), photo)));
    await assertSucceeds(getBytes(ref(admin().storage(), photo)));
    await assertFails(getBytes(ref(env.authenticatedContext('c2').storage(), photo)));
    await assertFails(getBytes(ref(env.unauthenticatedContext().storage(), photo)));
    await assertFails(put('c1', photo), 'no overwriting');
    await assertFails(deleteObject(ref(env.authenticatedContext('c1').storage(), photo)));
  });

  test('evidence can be added again after the client asks for changes, not while waiting for review', async () => {
    const ev = (name) => put('w1', `contracts/j1_w1/evidence/${name}`);
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now(), submittedAt: Timestamp.now(), submissionCount: 1, revisionCount: 1 }));
    await assertSucceeds(ev('round2.jpg'));
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now(), submittedAt: Timestamp.now(), submissionCount: 2, revisionCount: 1 }));
    await assertFails(ev('late.jpg'));
  });

  test('evidence is never replaced once uploaded', async () => {
    await seed('contracts/j1_w1', contractData({ workStartedAt: Timestamp.now() }));
    await assertSucceeds(put('w1', 'contracts/j1_w1/evidence/once.jpg'));
    await assertFails(put('w1', 'contracts/j1_w1/evidence/once.jpg'));
  });
});
