import { NextRequest, NextResponse } from 'next/server';
import { adminAuth, adminDb } from '@/lib/firebase/admin';

export async function POST(req: NextRequest) {
  try {
    const session = req.cookies.get('session')?.value;
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const decodedClaims = await adminAuth.verifySessionCookie(session);
    if (decodedClaims.role !== 'SUPER_ADMIN') {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const { uid, action, reason } = await req.json();

    if (!uid || !action) {
      return NextResponse.json({ error: 'Missing uid or action' }, { status: 400 });
    }

    let resultMsg = '';

    switch (action) {
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
      actorId: decodedClaims.uid,
      action: `USER_${action.toUpperCase()}`,
      targetId: uid,
      timestamp: new Date().toISOString(),
      reason: reason || 'No reason provided',
    });

    return NextResponse.json({ success: true, message: resultMsg });

  } catch (error: any) {
    console.error('User action error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
