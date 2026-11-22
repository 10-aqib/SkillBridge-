import { NextRequest, NextResponse } from 'next/server';
import { FieldValue } from 'firebase-admin/firestore';
import { adminDb } from '@/lib/firebase/admin';
import { getAdminRequestIdentity } from '@/lib/auth/admin-session';

/**
 * Staff actions on an identity verification session (NADRA track).
 *
 *  - `manual_review`: flag a session for additional review.
 *  - `request_retry`: close a finished session so the person can verify again
 *    (they are notified).
 *
 * There is deliberately NO action that sets an identity as verified: only an
 * authentic NADRA result, recorded by the trusted functions, can do that, and
 * the Firestore rules also stop staff from changing `identityVerification`.
 * Every action is written to auditLogs and to the session's own audit trail.
 */
const allowed: Record<string, Set<string>> = {
  manual_review: new Set(['pending', 'rejected', 'failed', 'expired']),
  request_retry: new Set(['rejected', 'failed', 'manual_review', 'expired']),
};

export async function POST(request: NextRequest) {
  const admin = await getAdminRequestIdentity(request);
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    const body: unknown = await request.json();
    const { sessionId, action, note } = (body && typeof body === 'object' ? body : {}) as Record<string, unknown>;
    if (typeof sessionId !== 'string' || !/^[A-Za-z0-9_-]{8,64}$/.test(sessionId) ||
        typeof action !== 'string' || !(action in allowed) ||
        (note !== undefined && typeof note !== 'string')) {
      return NextResponse.json({ error: 'Invalid identity action' }, { status: 400 });
    }
    const reason = typeof note === 'string' ? note.trim().slice(0, 1000) : '';
    const sessionRef = adminDb.collection('identityVerifications').doc(sessionId);
    const auditRef = adminDb.collection('auditLogs').doc();
    const eventRef = sessionRef.collection('events').doc();

    const result = await adminDb.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      if (!snap.exists) throw new Error('SESSION_NOT_FOUND');
      const s = snap.data() || {};
      const previous = String(s.status || '');
      if (!allowed[action].has(previous)) throw new Error('ACTION_NOT_ALLOWED');
      const userRef = adminDb.collection('users').doc(String(s.userId));
      const user = await tx.get(userRef);
      const current = (user.data()?.identityVerification || {}) as Record<string, unknown>;

      const next = action === 'manual_review' ? 'manual_review' : 'cancelled';
      tx.update(sessionRef, {
        status: next,
        failureCategory: action === 'manual_review' ? 'admin_review' : 'admin_requested_retry',
        updatedAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });
      // The account's status follows, but a genuine verification is never touched.
      if (user.exists && current.verified !== true) {
        tx.update(userRef, { 'identityVerification.status': next, updatedAt: FieldValue.serverTimestamp() });
      }
      tx.set(eventRef, { type: `admin_${action}`, actor: `admin:${admin.uid}`, at: FieldValue.serverTimestamp(), reason });
      tx.set(auditRef, {
        actorId: admin.uid,
        action: action === 'manual_review' ? 'IDENTITY_MARKED_FOR_REVIEW' : 'IDENTITY_RETRY_REQUESTED',
        targetId: String(s.userId),
        sessionId,
        previousStatus: previous,
        status: next,
        reason,
        timestamp: FieldValue.serverTimestamp(),
      });
      return { userId: String(s.userId), next };
    });

    if (action === 'request_retry') {
      // In-app notification (pushed by the notify function). No CNIC or biometric data.
      await adminDb.collection('notifications').doc(`identity_${sessionId}_retry`).set({
        userId: result.userId,
        title: 'Please verify your identity again',
        body: 'Our team asked you to repeat identity verification. Open SkillBridge to start.',
        type: 'identity_retry',
        payload: { requestId: sessionId },
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
        source: 'server',
        verifiedAt: FieldValue.serverTimestamp(),
      });
    }
    return NextResponse.json({ success: true, status: result.next });
  } catch (cause) {
    const message = cause instanceof Error ? cause.message : '';
    if (message === 'SESSION_NOT_FOUND') return NextResponse.json({ error: 'Session not found' }, { status: 404 });
    if (message === 'ACTION_NOT_ALLOWED') return NextResponse.json({ error: 'This action is not allowed for the session status' }, { status: 409 });
    console.error('Identity action error');
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
