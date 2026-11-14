import { NextRequest, NextResponse } from 'next/server';
import { FieldValue } from 'firebase-admin/firestore';
import { adminDb } from '@/lib/firebase/admin';
import { getAdminRequestIdentity } from '@/lib/auth/admin-session';

const allowedStatuses = new Set(['open', 'investigating', 'resolved']);

export async function PATCH(request: NextRequest) {
  const admin = await getAdminRequestIdentity(request);
  if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    const body: unknown = await request.json();
    if (!body || typeof body !== 'object') {
      return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
    }

    const { reportId, status, moderationNote } = body as Record<string, unknown>;
    if (typeof reportId !== 'string' || !reportId.trim() ||
        typeof status !== 'string' || !allowedStatuses.has(status) ||
        (moderationNote !== undefined && typeof moderationNote !== 'string')) {
      return NextResponse.json({ error: 'Invalid moderation update' }, { status: 400 });
    }

    const reportRef = adminDb.collection('reports').doc(reportId);
    const auditRef = adminDb.collection('auditLogs').doc();
    await adminDb.runTransaction(async (transaction) => {
      const report = await transaction.get(reportRef);
      if (!report.exists) throw new Error('REPORT_NOT_FOUND');
      const previousStatus = String(report.data()?.status || 'open');
      const note = typeof moderationNote === 'string' ? moderationNote.trim().slice(0, 2000) : '';

      transaction.update(reportRef, {
        status,
        moderationNote: note,
        moderatedBy: admin.uid,
        moderatedAt: FieldValue.serverTimestamp(),
      });
      transaction.set(auditRef, {
        actorId: admin.uid,
        action: 'REPORT_STATUS_UPDATED',
        targetId: reportId,
        previousStatus,
        status,
        reason: note,
        timestamp: FieldValue.serverTimestamp(),
      });
    });

    return NextResponse.json({ success: true });
  } catch (error) {
    if (error instanceof Error && error.message === 'REPORT_NOT_FOUND') {
      return NextResponse.json({ error: 'Report not found' }, { status: 404 });
    }
    console.error('Report moderation failed:', error);
    return NextResponse.json({ error: 'Could not update report' }, { status: 500 });
  }
}
