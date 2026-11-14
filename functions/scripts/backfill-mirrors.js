#!/usr/bin/env node
// One-off, additive backfill of publicProfiles/{uid} and liveLocations/{uid}
// for accounts created before the mirror functions were deployed.
// It reads users/* and writes only the two mirror collections; users/* is
// never modified or deleted.
//
// Emulator:   FIRESTORE_EMULATOR_HOST=127.0.0.1:8181 node scripts/backfill-mirrors.js --project <id>
// Production: needs explicit approval, Admin credentials, and --confirm-production.
//
// Build first: npm run build (the script uses the compiled lib/profiles.js).

const admin = require("firebase-admin");

const args = process.argv.slice(2);
const project = args[args.indexOf("--project") + 1];
const onEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
if (!project || args.indexOf("--project") < 0) {
  console.error("Usage: node scripts/backfill-mirrors.js --project <projectId> [--confirm-production]");
  process.exit(2);
}
if (!onEmulator && !args.includes("--confirm-production")) {
  console.error("Refusing to write to a real project without --confirm-production.");
  process.exit(2);
}

admin.initializeApp({ projectId: project });
const { backfillMirrors } = require("../lib/profiles.js");

backfillMirrors(admin.firestore())
  .then((r) => {
    console.log(`publicProfiles written: ${r.profiles}; liveLocations written: ${r.live}`);
    process.exit(0);
  })
  .catch((e) => {
    console.error(e);
    process.exit(1);
  });
