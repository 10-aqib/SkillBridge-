/**
 * Staff sign in with a username such as `skillbridge@admin`, not an email.
 * Firebase only accepts real email addresses, so a username becomes an
 * internal address on the project's own Firebase domain, which has no
 * mailbox: `skillbridge@admin` → `skillbridge.admin@skill-bridge-c68c3.firebaseapp.com`.
 * Same rule as the mobile app (AppConstants.staffEmailForUsername) and
 * create-admin.js; keep them in step.
 */
export const STAFF_EMAIL_DOMAIN = 'skill-bridge-c68c3.firebaseapp.com';

const STAFF_USERNAME = /^[a-z0-9._-]{2,40}@[a-z0-9-]{2,30}$/;

/** The address to sign in with: a staff username's internal address, or the input as typed. */
export function signInEmail(input: string): string {
  const v = input.trim().toLowerCase();
  return STAFF_USERNAME.test(v) ? `${v.replace('@', '.')}@${STAFF_EMAIL_DOMAIN}` : input.trim();
}
