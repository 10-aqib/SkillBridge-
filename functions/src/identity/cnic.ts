// CNIC handling for identity verification. The full number is only ever held
// in memory for the duration of a request: records keep a masked form and a
// keyed digest (HMAC) used to stop one CNIC being verified on two accounts.

import { createHmac } from "crypto";

/** The 13 digits of a CNIC typed as XXXXX-XXXXXXX-X (or digits only), or null. */
export function cnicDigits(input: unknown): string | null {
  if (typeof input !== "string") return null;
  const trimmed = input.trim();
  if (!/^(\d{5}-\d{7}-\d|\d{13})$/.test(trimmed)) return null;
  const digits = trimmed.replace(/-/g, "");
  if (digits[0] === "0") return null; // no real CNIC starts with 0
  if (/^(\d)\1{12}$/.test(digits)) return null; // 1111111111111 etc.
  return digits;
}

/** "35202-•••••••-1": area code and check digit only. */
export function maskCnic(digits: string): string {
  return `${digits.slice(0, 5)}-•••••••-${digits.slice(12)}`;
}

/** Keyed digest of the CNIC (never reversible without the server pepper). */
export function cnicDigest(digits: string, pepper: string): string {
  return createHmac("sha256", pepper).update(`cnic:${digits}`).digest("hex");
}

/**
 * Synthetic identities for the test simulator. Real CNICs never start with
 * 9999; the simulator accepts nothing else, so no real person's CNIC is
 * ever used in testing.
 */
export const SYNTHETIC_PREFIX = "99999";
export const isSyntheticCnic = (digits: string) => digits.startsWith(SYNTHETIC_PREFIX);
