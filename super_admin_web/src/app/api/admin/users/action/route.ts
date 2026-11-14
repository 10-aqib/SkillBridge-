import { NextRequest, NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase/admin';
import { getAdminRequestIdentity, isSuperAdmin } from '@/lib/auth/admin-session';

export async function POST(req: NextRequest) {
  try {
    const admin = await getAdminRequestIdentity(req);
    if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    if (!isSuperAdmin(admin)) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const body: unknown = await req.json();
    if (!body || typeof body !== 'object') {
      return NextResponse.json({ error: 'Invalid request body' }, { status: 400 });
    }
    const { uid, action, reason } = body as Record<string, unknown>;
    const actionName = typeof action === 'string' ? action : '';

    if (typeof uid !== 'string' || !uid.trim() ||
        !['suspend', 'restore', 'delete'].includes(actionName) ||
        (reason !== undefined && typeof reason !== 'string')) {
      return NextResponse.json({ error: 'Missing uid or action' }, { status: 400 });
    }
    if (uid === admin.uid && action !== 'restore') {
      return NextResponse.json({ error: 'You cannot suspend or delete your own administrator account.' }, { status: 400 });
    }

    let resultMsg = '';

    switch (actionName) {
      case 'suspend':
        await adminAuth.updateUser(uid, { disabled: true });
        resultMsg = 'User suspended successfully';
        break;
      case 'restore':
        await adminAuth.updateUser(uid, { disabled: false });
        resultMsg = 'User restored successfully';
        break;
      case 'delete':
        await adminAuth.deleteUser(uid);
        await adminDb.collection('users').doc(uid).delete();
        resultMsg = 'User deleted successfully';
        break;
      default:
        return NextResponse.json({ error: 'Invalid action' }, { status: 400 });
    }

    // Log the action securely
    await adminDb.collection('auditLogs').add({
      actorId: admin.uid,
      action: `USER_${actionName.toUpperCase()}`,
      targetId: uid,
      timestamp: new Date(),
      reason: typeof reason === 'string' ? reason.trim().slice(0, 1000) : '',
    });

    return NextResponse.json({ success: true, message: resultMsg });

  } catch (error) {
    console.error('User action error:', error);
    return NextResponse.json({ error: error instanceof Error ? error.message : 'Internal Server Error' }, { status: 500 });
  }
}
