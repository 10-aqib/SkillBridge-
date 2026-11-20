#!/usr/bin/env node
// Seeds 30 fictional test workers (Islamabad / Rawalpindi) into the LOCAL
// Firebase emulators, for testing discovery, hiring and contracts.
//
// Per worker it creates:
//   - an Auth account  worker01@skillbridge.test … worker30@skillbridge.test
//     (email verified; one shared test password, see below)
//   - users/{uid}            the private account, shaped like the app writes it
//   - publicProfiles/{uid}   the allowlisted public view, built the same way as
//                            publicProfileOf() in lib/core/services/public_profile_sync.dart
// Everything is tagged isTestData: true (private account only; the public
// view must stay allowlisted). Re-running updates the same 30 accounts.
// Remove them with --delete.
//
// Workers start with no reviews or rating, the same as a real new signup.
// Reviews need completed contracts, so make those through the app.
//
// Usage (emulators running; firebase-admin comes from functions/node_modules):
//   cd functions
//   set FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
//   set FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
//   node scripts/seed-test-workers.js --project demo-skillbridge [--photo-base <url>] [--delete]
//
// --photo-base defaults to the raw GitHub URL of assets/seed_workers/ on the
// ui-improvements-2026 branch. Those links work once the photos are pushed.
//
// The test password is generated on the first run and kept in
// scripts/.seed-workers.local.json (git-ignored). It is never printed.
//
// Production: refused. This script only runs against the emulators.

const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const admin = require("firebase-admin");
const workers = require("./seed-test-workers.data.js");

const args = process.argv.slice(2);
const arg = (name) => {
  const i = args.indexOf(name);
  return i >= 0 ? args[i + 1] : undefined;
};
const project = arg("--project");
const remove = args.includes("--delete");
const photoBase = (arg("--photo-base") ||
  "https://raw.githubusercontent.com/10-aqib/SkillBridge-/ui-improvements-2026/assets/seed_workers").replace(/\/+$/, "");

if (!project) {
  console.error("Usage: node scripts/seed-test-workers.js --project <projectId> [--photo-base <url>] [--delete]");
  process.exit(2);
}
if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error("Refusing to run: set FIRESTORE_EMULATOR_HOST and FIREBASE_AUTH_EMULATOR_HOST.");
  console.error("This script writes test data to the local emulators only.");
  process.exit(2);
}

admin.initializeApp({ projectId: project });
const db = admin.firestore();
const auth = admin.auth();
const { GeoPoint, Timestamp } = admin.firestore;

const CATEGORY_NAMES = {
  electrician: "Electrician", plumber: "Plumber", ac_technician: "AC Technician",
  solar_installer: "Solar Installer", generator_ups: "UPS & Generator", mechanic: "Mechanic",
  painter: "Painter", carpenter: "Carpenter", tutor: "Home Tutor", driver: "Driver",
  cleaner: "House Cleaner", mason: "Mason / Builder",
};

// Same algorithm and precision as GeohashUtil.encode (lib/core/utils/geohash_util.dart).
function geohash(lat, lng, precision = 9) {
  const base32 = "0123456789bcdefghjkmnpqrstuvwxyz";
  let even = true, bit = 0, ch = 0, hash = "";
  let minLat = -90, maxLat = 90, minLng = -180, maxLng = 180;
  while (hash.length < precision) {
    if (even) {
      const mid = (minLng + maxLng) / 2;
      if (lng > mid) { ch |= 1 << (4 - bit); minLng = mid; } else { maxLng = mid; }
    } else {
      const mid = (minLat + maxLat) / 2;
      if (lat > mid) { ch |= 1 << (4 - bit); minLat = mid; } else { maxLat = mid; }
    }
    even = !even;
    if (bit < 4) { bit++; } else { hash += base32[ch]; bit = 0; ch = 0; }
  }
  return hash;
}

// ~1.1 km, as coarse() in public_profile_sync.dart.
const coarse = (v) => Math.round(v * 100) / 100;

const PUBLIC_USER_FIELDS = ["displayName", "photoUrl", "role", "isActive", "city",
  "isEmailVerified", "isPhoneVerified", "isCnicVerified", "createdAt", "rating", "totalReviews"];
const PUBLIC_WORKER_FIELDS = ["headline", "bio", "categoryId", "categoryName", "skills", "experience",
  "hourlyRate", "dailyRate", "availability", "isVerified", "city", "serviceRadius",
  "totalJobsCompleted", "averageRating", "totalReviews", "coverImage", "languages",
  "responseTime", "portfolioImages", "beforeAfterImages"];

function publicProfileOf(uid, user) {
  const out = { uid };
  for (const f of PUBLIC_USER_FIELDS) if (user[f] !== undefined && user[f] !== null) out[f] = user[f];
  const lat = coarse(user.location.latitude), lng = coarse(user.location.longitude);
  out.location = new GeoPoint(lat, lng);
  out.geohash = geohash(lat, lng);
  out.locationAccuracy = "approximate";
  const src = user.workerProfile, pub = {};
  for (const f of PUBLIC_WORKER_FIELDS) if (src[f] !== undefined && src[f] !== null) pub[f] = src[f];
  pub.certifications = src.certifications.slice(0, 20).map(({ name, issuedBy, year }) => ({ name, issuedBy, year }));
  pub.location = new GeoPoint(lat, lng);
  pub.geohash = geohash(lat, lng);
  pub.locationAccuracy = "approximate";
  out.workerProfile = pub;
  return out;
}

function testPassword() {
  const file = path.join(__dirname, ".seed-workers.local.json");
  if (fs.existsSync(file)) return JSON.parse(fs.readFileSync(file, "utf8")).password;
  const password = "Sb-" + crypto.randomBytes(9).toString("base64url");
  fs.writeFileSync(file, JSON.stringify({ password }, null, 2) + "\n");
  return password;
}

const emailOf = (i) => `worker${String(i + 1).padStart(2, "0")}@skillbridge.test`;

function accountOf(uid, w, i) {
  const now = Date.now();
  // Spread sign-up dates over the last ~2 years so "member since" varies.
  const created = Timestamp.fromMillis(now - (40 + ((i * 23) % 700)) * 86400000);
  const location = new GeoPoint(w.lat, w.lng);
  const hash = geohash(w.lat, w.lng);
  const address = `${w.area}, ${w.city}`;
  const verified = w.verified === "verified";
  const workerProfile = {
    headline: w.headline,
    bio: w.bio,
    categoryId: w.categoryId,
    categoryName: CATEGORY_NAMES[w.categoryId],
    skills: w.skills,
    experience: w.experience,
    hourlyRate: w.hourlyRate,
    dailyRate: w.dailyRate,
    certifications: w.certifications,
    portfolioImages: [],
    availability: w.availability,
    isVerified: verified,
    ...(w.verified ? { verificationStatus: w.verified } : {}),
    ...(verified ? { verifiedAt: created } : {}),
    city: w.city,
    address,
    location,
    serviceRadius: w.serviceRadius,
    totalJobsCompleted: w.totalJobsCompleted,
    totalEarnings: 0,
    averageRating: 0,
    totalReviews: 0,
    geohash: hash,
    locationAccuracy: "20.0",
    locationAddress: address,
    languages: w.languages,
    responseTime: w.responseTime,
    beforeAfterImages: [],
  };
  return {
    uid,
    email: emailOf(i),
    displayName: w.name,
    phoneNumber: "",
    photoUrl: `${photoBase}/${w.photo}`,
    role: "worker",
    isEmailVerified: true,
    isPhoneVerified: false,
    isCnicVerified: verified,
    isActive: true,
    createdAt: created,
    updatedAt: Timestamp.fromMillis(now),
    address,
    city: w.city,
    location,
    isLocationSharing: false,
    geohash: hash,
    locationAccuracy: "20.0",
    locationAddress: address,
    locationVisibility: "public",
    totalJobsPosted: 0,
    totalHires: 0,
    rating: 0,
    totalReviews: 0,
    workerProfile,
    onboardingCompleted: true,
    isTestData: true,
  };
}

async function findUid(email) {
  try { return (await auth.getUserByEmail(email)).uid; } catch (e) {
    if (e.code === "auth/user-not-found") return null;
    throw e;
  }
}

async function seed() {
  if (workers.length !== 30) throw new Error(`Expected 30 workers, found ${workers.length}.`);
  const password = testPassword();
  const batch = db.batch();
  for (const [i, w] of workers.entries()) {
    const email = emailOf(i);
    let uid = await findUid(email);
    if (uid) {
      await auth.updateUser(uid, { displayName: w.name, password, emailVerified: true });
    } else {
      uid = (await auth.createUser({ email, password, displayName: w.name, emailVerified: true })).uid;
    }
    const user = accountOf(uid, w, i);
    batch.set(db.collection("users").doc(uid), user);
    batch.set(db.collection("publicProfiles").doc(uid), publicProfileOf(uid, user));
    console.log(`${email}  ${w.name}  (${CATEGORY_NAMES[w.categoryId]}, ${w.area})`);
  }
  await batch.commit();
  console.log(`\nSeeded ${workers.length} workers into project ${project}.`);
  console.log("Sign in as any of them with the password in scripts/.seed-workers.local.json.");
}

async function unseed() {
  let n = 0;
  for (let i = 0; i < workers.length; i++) {
    const uid = await findUid(emailOf(i));
    if (!uid) continue;
    await db.collection("publicProfiles").doc(uid).delete();
    await db.collection("users").doc(uid).delete();
    await auth.deleteUser(uid);
    n++;
  }
  console.log(`Deleted ${n} test workers from project ${project}.`);
}

(remove ? unseed() : seed()).catch((e) => {
  console.error(e.message || e);
  process.exit(1);
});
