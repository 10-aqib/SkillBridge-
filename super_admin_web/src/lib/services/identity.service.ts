import { adminDb } from '@/lib/firebase/admin';

/**
 * Identity verification sessions for staff (NADRA track). Staff see status,
 * dates, user, role, provider, masked CNIC, transaction reference and the
 * technical failure category. They never see the full CNIC, the CNIC digest,
 * fingerprints, templates or provider payloads (none are stored).
 */
export interface IdentityRequestItem {
  id: string;
  userId: string;
  userName: string;
  userRole: string;
  provider: string;
  test: boolean;
  status: string;
  maskedCnic: string;
  failureCategory: string;
  transactionReference: string;
  attempts: number;
  createdAt: string;
  completedAt: string;
}

const iso = (v: unknown): string => {
  if (v && typeof (v as { toDate?: () => Date }).toDate === 'function') return (v as { toDate: () => Date }).toDate().toISOString();
  if (v instanceof Date) return v.toISOString();
  return '';
};

export class IdentityService {
  static async getRequests(limit = 200): Promise<IdentityRequestItem[]> {
    const snapshot = await adminDb.collection('identityVerifications').orderBy('createdAt', 'desc').limit(limit).get();
    const userIds = [...new Set(snapshot.docs.map((d) => String(d.data().userId || '')).filter(Boolean))];
    const users = await Promise.all(userIds.map((uid) => adminDb.collection('users').doc(uid).get()));
    const names = new Map(users.map((u) => [u.id, String(u.data()?.displayName || '')]));
    return snapshot.docs.map((d) => {
      const s = d.data();
      return {
        id: d.id,
        userId: String(s.userId || ''),
        userName: names.get(String(s.userId || '')) || '',
        userRole: String(s.userRole || ''),
        provider: String(s.provider || ''),
        test: s.test === true,
        status: String(s.status || ''),
        maskedCnic: String(s.maskedCnic || ''),
        failureCategory: String(s.failureCategory || ''),
        transactionReference: String(s.transactionReference || ''),
        attempts: typeof s.attempts === 'number' ? s.attempts : 0,
        createdAt: iso(s.createdAt),
        completedAt: iso(s.completedAt),
      };
    });
  }
}
