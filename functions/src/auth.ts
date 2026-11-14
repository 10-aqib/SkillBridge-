import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { onDocumentWritten } from "firebase-functions/v2/firestore";

/** Roles a person can choose for themselves in the app. */
const SELF_SERVICE_ROLES = new Set(["client", "worker"]);
/** Roles only granted by staff tooling (create-admin.js / setup-admin API). */
const STAFF_ROLES = new Set(["admin", "SUPER_ADMIN"]);

/**
 * New Firebase Auth account.
 *
 * Previously this merged `role: "client"` into users/{uid}, which raced with
 * the app writing the role the person chose (a new worker could silently
 * become a client, or worker sign-up could be rejected by the rules). It also
 * set a `client` claim that could overwrite staff claims set by
 * create-admin.js if this trigger ran second.
 *
 * Now it never writes Firestore and only sets a default `client` claim when
 * the account has no role claim yet. The real role claim is synced from the
 * profile by `syncUserRoleClaim`.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  try {
    const current = (await admin.auth().getUser(user.uid)).customClaims ?? {};
    if (typeof current.role === "string" && current.role.length > 0) {
      return;
    }
    await admin.auth().setCustomUserClaims(user.uid, { ...current, role: "client" });
    console.log(`Default client claim set for ${user.uid}`);
  } catch (error) {
    console.error("onUserCreated: could not set default claim", error);
  }
});

/**
 * Keeps the `role` custom claim in step with the client/worker role saved on
 * users/{uid}. Never grants or removes staff roles: a Firestore role of
 * "admin" is ignored, and accounts that already hold a staff claim are left
 * untouched.
 */
/**
 * Decides the role claim to set, or null to leave claims untouched.
 *
 * The Firestore role is client-written, so it is never trusted for privilege:
 * only "client"/"worker" are ever mirrored (the rules already restrict client
 * writes to those, chosen once), staff claims are never granted, replaced or
 * removed here, and any other value (e.g. a forged "admin") is ignored.
 */
export function nextRoleClaim(
  beforeRole: unknown,
  afterRole: unknown,
  currentClaim: unknown,
): string | null {
  if (typeof afterRole !== "string" || !SELF_SERVICE_ROLES.has(afterRole)) return null;
  if (beforeRole === afterRole && currentClaim === afterRole) return null;
  if (typeof currentClaim === "string" && STAFF_ROLES.has(currentClaim)) return null;
  if (currentClaim === afterRole) return null;
  return afterRole;
}

export const syncUserRoleClaim = onDocumentWritten("users/{uid}", async (event) => {
  const after = event.data?.after?.data();
  if (!after) return; // deleted
  const before = event.data?.before?.data();
  // Cheap exit before touching Auth when nothing role-related changed.
  if (typeof after.role !== "string" || !SELF_SERVICE_ROLES.has(after.role)) return;
  if (before && before.role === after.role) return;

  const uid = event.params.uid;
  try {
    const claims = (await admin.auth().getUser(uid)).customClaims ?? {};
    const role = nextRoleClaim(before?.role, after.role, claims.role);
    if (role === null) return;
    await admin.auth().setCustomUserClaims(uid, { ...claims, role });
    console.log(`Role claim for ${uid} synced to ${role}`);
  } catch (error) {
    console.error(`syncUserRoleClaim: failed for ${uid}`, error);
  }
});
