import { NextRequest, NextResponse } from 'next/server';
import { adminAuth } from '@/lib/firebase/admin';
import { adminDb } from '@/lib/firebase/admin';

export async function POST(request: NextRequest) {
  try {
    const { idToken } = await request.json();

    if (!idToken) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const decodedIdToken = await adminAuth.verifyIdToken(idToken, true);
    
    // Check if the user has an administrative role
    if (!['SUPER_ADMIN', 'admin', 'super_admin'].includes(String(decodedIdToken.role))) {
      return NextResponse.json({ error: 'Forbidden: Requires Administrative Role' }, { status: 403 });
    }

    // Create session cookie expires in 5 days
    const expiresIn = 60 * 60 * 24 * 5 * 1000; 
    const sessionCookie = await adminAuth.createSessionCookie(idToken, { expiresIn });

    try {
      await adminDb.collection('auditLogs').add({
        actorId: decodedIdToken.uid,
        action: 'ADMIN_SESSION_CREATED',
        targetId: decodedIdToken.uid,
        timestamp: new Date(),
        reason: 'Administrator signed in to the web console.',
      });
    } catch (auditError) {
      console.warn('Could not record administrator sign-in audit event:', auditError);
    }

    const response = NextResponse.json({ success: true, role: decodedIdToken.role }, { status: 200 });

    response.cookies.set('session', sessionCookie, {
      maxAge: expiresIn / 1000,
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      path: '/',
      sameSite: 'lax',
    });

    return response;
  } catch (error) {
    console.error('Session creation error', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}

export async function DELETE() {
  // Clear this portal's cookie without revoking Firebase sessions used by the mobile app.
  const response = NextResponse.json({ success: true }, { status: 200 });
  response.cookies.set('session', '', { maxAge: 0, path: '/' });
  return response;
}
