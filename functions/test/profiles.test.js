// Public/private profile mirrors, live-location access and the job-status
// copy on proposals. Runs against a small in-memory stand-in for Firestore.
const test = require("node:test");
const assert = require("node:assert/strict");
const {
  publicProfileOf,
  geohashEncode,
  coarse,
  sameValue,
  liveFieldsChanged,
  liveLocationOf,
  activeClientIds,
  syncLiveLocation,
  syncPublicProfile,
  backfillMirrors,
} = require("../.test-build/profiles.js");
const { mirrorJobStatus, workersToRefresh } = require("../.test-build/proposals.js");

function fakeDb(seed = {}) {
  const data = {};
  for (const [col, docs] of Object.entries(seed)) data[col] = JSON.parse(JSON.stringify(docs));
  const writes = [];
  const coll = (col) => (data[col] ??= {});
  const snap = (col, id) => ({
    id,
    exists: coll(col)[id] !== undefined,
    get: (f) => coll(col)[id]?.[f],
    data: () => coll(col)[id],
    ref: ref(col, id),
  });
  const ref = (col, id) => ({
    id,
    path: `${col}/${id}`,
    get: async () => snap(col, id),
    set: async (v) => { writes.push(["set", `${col}/${id}`]); coll(col)[id] = v; },
    delete: async () => { writes.push(["delete", `${col}/${id}`]); delete coll(col)[id]; },
  });
  const query = (col, filters = [], opts = {}) => ({
    where: (f, op, v) => query(col, [...filters, [f, op, v]], opts),
    orderBy: () => query(col, filters, opts),
    limit: (n) => query(col, filters, { ...opts, limit: n }),
    startAfter: (d) => query(col, filters, { ...opts, after: d.id }),
    get: async () => {
      let ids = Object.keys(coll(col)).sort().filter((id) =>
        filters.every(([f, op, v]) => (op === "in" ? v.includes(coll(col)[id][f]) : coll(col)[id][f] === v)));
      if (opts.after) ids = ids.filter((id) => id > opts.after);
      if (opts.limit) ids = ids.slice(0, opts.limit);
      const docs = ids.map((id) => snap(col, id));
      return { empty: docs.length === 0, size: docs.length, docs };
    },
  });
  return {
    data,
    writes,
    collection: (col) => ({ doc: (id) => ref(col, id), where: (f, op, v) => query(col, [[f, op, v]]), orderBy: () => query(col) }),
    batch: () => {
      const pending = [];
      return {
        update: (r, patch) => pending.push([r, patch]),
        commit: async () => {
          for (const [r, patch] of pending) {
            const [col, id] = r.path.split("/");
            writes.push(["update", r.path]);
            Object.assign(coll(col)[id], patch);
          }
        },
      };
    },
  };
}

const worker = {
  uid: "w1",
  role: "worker",
  displayName: "Bilal Ahmed",
  email: "bilal@example.com",
  phoneNumber: "+923001234567",
  cnicNumber: "35202-1234567-1",
  fcmToken: "token-123",
  address: "House 5, Street 2, Gulberg III",
  city: "Lahore",
  isActive: true,
  isEmailVerified: true,
  isPhoneVerified: false,
  isCnicVerified: false,
  rating: 4.5,
  totalReviews: 2,
  onboardingCompleted: true,
  location: { latitude: 31.520367, longitude: 74.358749 },
  isLocationSharing: true,
  heading: 90,
  locationVisibility: "public",
  workerProfile: {
    headline: "Certified electrician",
    skills: ["House wiring"],
    experience: 7,
    hourlyRate: 800,
    portfolioImages: ["https://example.com/p1.jpg"],
    isVerified: true,
    verificationStatus: "approved",
    verificationDocUrl: "verification/w1/cnic.jpg",
    totalEarnings: 125000,
    address: "House 5, Street 2",
    locationAddress: "House 5, Street 2, Gulberg III, Lahore",
    location: { latitude: 31.520367, longitude: 74.358749 },
    certifications: [{ name: "Electrical L2", issuedBy: "TEVTA", year: 2021, imageUrl: "private/cert.jpg" }],
  },
};

test("public profiles leave out every private field", () => {
  const pub = publicProfileOf("w1", worker);
  const flat = JSON.stringify(pub);
  for (const secret of ["+923001234567", "bilal@example.com", "35202-1234567-1", "token-123", "House 5", "125000", "verification/w1", "private/cert.jpg", "approved"]) {
    assert.ok(!flat.includes(secret), `leaked ${secret}`);
  }
  for (const key of ["phoneNumber", "email", "cnicNumber", "fcmToken", "address", "onboardingCompleted", "isLocationSharing", "heading", "locationVisibility"]) {
    assert.equal(key in pub, false, key);
  }
  for (const key of ["totalEarnings", "verificationDocUrl", "verificationStatus", "address", "locationAddress"]) {
    assert.equal(key in pub.workerProfile, false, key);
  }
  assert.equal(pub.displayName, "Bilal Ahmed");
  assert.equal(pub.isEmailVerified, true);
  assert.deepEqual(pub.workerProfile.skills, ["House wiring"]);
  assert.deepEqual(pub.workerProfile.portfolioImages, ["https://example.com/p1.jpg"]);
  assert.deepEqual(pub.workerProfile.certifications, [{ name: "Electrical L2", issuedBy: "TEVTA", year: 2021 }]);
});

test("worker locations are coarsened to about 1 km with a matching geohash", () => {
  const pub = publicProfileOf("w1", worker);
  assert.equal(pub.location.latitude, 31.52);
  assert.equal(pub.location.longitude, 74.36);
  assert.equal(pub.geohash, geohashEncode(31.52, 74.36));
  assert.equal(pub.locationAccuracy, "approximate");
  assert.equal(pub.workerProfile.location.latitude, 31.52);
  assert.equal(coarse(31.5249), 31.52);
});

test("geohash matches the standard algorithm (and the app's GeohashUtil)", () => {
  assert.equal(geohashEncode(57.64911, 10.40744, 11), "u4pruydqqvj");
});

test("clients never get a public location; hidden worker areas stay hidden", () => {
  const client = { role: "client", displayName: "Ayesha", phoneNumber: "+923331112223", location: { latitude: 31.5, longitude: 74.3 } };
  const pub = publicProfileOf("c1", client);
  assert.equal("location" in pub, false);
  assert.equal("geohash" in pub, false);
  assert.equal("workerProfile" in pub, false);
  const hidden = publicProfileOf("w1", { ...worker, locationVisibility: "private" });
  assert.equal("location" in hidden, false);
  assert.equal("location" in hidden.workerProfile, false);
});

test("the public mirror is rewritten only when the public view changes", async () => {
  const db = fakeDb();
  assert.equal(await syncPublicProfile(db, "w1", worker), "written");
  const tokenOnly = { ...worker, fcmToken: "token-456" };
  assert.equal(await syncPublicProfile(db, "w1", tokenOnly), "unchanged");
  const nearby = { ...worker, location: { latitude: 31.5204, longitude: 74.3588 } };
  assert.equal(await syncPublicProfile(db, "w1", nearby), "unchanged", "same ~1 km cell");
  assert.equal(await syncPublicProfile(db, "w1", { ...worker, displayName: "Bilal A." }), "written");
  // A user created before the function existed gets a mirror on their next write.
  delete db.data.publicProfiles.w1;
  assert.equal(await syncPublicProfile(db, "w1", tokenOnly), "written");
  assert.equal(await syncPublicProfile(db, "w1", undefined), "removed");
  assert.equal(db.data.publicProfiles.w1, undefined);
});

test("a mirror left stale by an earlier failed run is corrected on the next write", async () => {
  // Found in the emulator run: the first write crashed, the second (same
  // ~1 km cell) must still bring the location into the mirror.
  const noLocation = { ...worker };
  delete noLocation.location;
  delete noLocation.workerProfile;
  const db = fakeDb({ publicProfiles: { w1: publicProfileOf("w1", noLocation) } });
  assert.equal("location" in db.data.publicProfiles.w1, false);
  assert.equal(await syncPublicProfile(db, "w1", worker), "written");
  assert.equal(db.data.publicProfiles.w1.location.latitude, 31.52);
});

test("live location goes only to clients of jobs currently assigned to the worker", async () => {
  const db = fakeDb({
    users: { w1: worker },
    jobs: {
      j1: { clientId: "c1", selectedWorkerId: "w1", status: "assigned" },
      j2: { clientId: "c2", selectedWorkerId: "w1", status: "in_progress" },
      j3: { clientId: "c3", selectedWorkerId: "w1", status: "completed" },
      j4: { clientId: "c4", selectedWorkerId: "w9", status: "assigned" },
      j5: { clientId: "c5", selectedWorkerId: "w1", status: "open" },
    },
  });
  assert.deepEqual(await activeClientIds(db, "w1"), ["c1", "c2"]);
  assert.equal(await syncLiveLocation(db, "w1"), "written");
  const live = db.data.liveLocations.w1;
  assert.deepEqual(live.viewerIds, ["c1", "c2"]);
  assert.equal(live.location.latitude, 31.520367, "exact position for the viewers who need it");
  assert.equal(JSON.stringify(live).includes("+92"), false);

  // Job finished: nobody may follow the worker any more.
  db.data.jobs.j1.status = "completed";
  db.data.jobs.j2.status = "completed";
  assert.equal(await syncLiveLocation(db, "w1"), "removed");
  assert.equal(db.data.liveLocations.w1, undefined);
  assert.equal(await syncLiveLocation(db, "w1"), "skipped");
});

test("without sharing, viewers see that sharing is off but no position", () => {
  const live = liveLocationOf("w1", { ...worker, isLocationSharing: false }, ["c1"]);
  assert.equal(live.isLocationSharing, false);
  assert.equal(live.location, null);
  assert.equal(live.heading, null);
});

test("only location-related writes refresh the live mirror", () => {
  assert.equal(liveFieldsChanged(worker, { ...worker, fcmToken: "x" }), false);
  assert.equal(liveFieldsChanged(worker, { ...worker, heading: 180 }), true);
  assert.equal(liveFieldsChanged(worker, { ...worker, isLocationSharing: false }), true);
  assert.equal(sameValue({ a: 1, b: [1, 2] }, { b: [1, 2], a: 1 }), true);
});

test("job status is copied to its proposals, writing only stale copies", async () => {
  const db = fakeDb({
    proposals: {
      j1_w1: { jobId: "j1", status: "accepted", jobStatus: "open" },
      j1_w2: { jobId: "j1", status: "rejected" },
      j1_w3: { jobId: "j1", status: "withdrawn", jobStatus: "assigned" },
      j2_w1: { jobId: "j2", status: "pending", jobStatus: "open" },
    },
  });
  assert.equal(await mirrorJobStatus(db, "j1", "assigned"), 2);
  assert.equal(db.data.proposals.j1_w1.jobStatus, "assigned");
  assert.equal(db.data.proposals.j1_w2.jobStatus, "assigned");
  assert.equal(db.data.proposals.j2_w1.jobStatus, "open", "other jobs untouched");
  assert.equal(await mirrorJobStatus(db, "j1", "assigned"), 0, "repeat is a no-op");
});

test("hiring, reassigning or finishing refreshes the affected workers' viewers", () => {
  assert.deepEqual(workersToRefresh({ status: "open" }, { status: "assigned", selectedWorkerId: "w1" }), ["w1"]);
  assert.deepEqual(workersToRefresh({ status: "assigned", selectedWorkerId: "w1" }, { status: "assigned", selectedWorkerId: "w2" }).sort(), ["w1", "w2"]);
  assert.deepEqual(workersToRefresh({ status: "assigned", selectedWorkerId: "w1" }, { status: "assigned", selectedWorkerId: "w1", title: "x" }), []);
});

test("backfill is additive: it writes mirrors and never touches users", async () => {
  const db = fakeDb({
    users: { c1: { role: "client", displayName: "Ayesha", phoneNumber: "+923331112223" }, w1: worker },
    jobs: { j1: { clientId: "c1", selectedWorkerId: "w1", status: "assigned" } },
  });
  const before = JSON.stringify(db.data.users);
  const r = await backfillMirrors(db, 1);
  assert.deepEqual(r, { profiles: 2, live: 1 });
  assert.equal(JSON.stringify(db.data.users), before);
  assert.equal(db.writes.some(([, path]) => path.startsWith("users/")), false);
  assert.equal(db.data.publicProfiles.c1.displayName, "Ayesha");
  assert.equal("phoneNumber" in db.data.publicProfiles.c1, false);
});
