import * as admin from "firebase-admin";

admin.initializeApp();

// Phase G (Blaze): only the jobs the app must not do itself.
// Contracts, proposals, chats, ratings and public profiles are written by
// the app in transactions and checked by firestore.rules (free-plan design,
// phases S2–S5); the old triggers that did that work were removed in G5,
// because running them as well would count everything twice.
export * from "./maps"; // computeRoute, searchPlaces, reverseGeocode (G3)
export * from "./notify"; // onNotificationCreatedV2: trusted text + push (G5)
export * from "./profileCopies"; // refreshProfileCopies: name/photo copies (G5)
export * from "./account"; // deleteAccount: in-app account deletion (G6)
export * from "./identity"; // NADRA fingerprint identity verification (gated; simulator on emulator only)
