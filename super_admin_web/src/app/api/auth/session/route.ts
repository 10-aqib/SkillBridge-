import { NextRequest, NextResponse } from 'next/server';
import { adminAuth } from '@/lib/firebase/admin';

export async function POST(request: NextRequest) {
  try {
    const { idToken } = await request.json();

    if (!idToken) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const decodedIdToken = await adminAuth.verifyIdToken(idToken);
    
    // Check if the user has the SUPER_ADMIN claim
    if (decodedIdToken.role !== 'SUPER_ADMIN') {
      return NextResponse.json({ error: 'Forbidden: Requires Super Admin Role' }, { status: 403 });
    }

    // Create session cookie expires in 5 days
    const expiresIn = 60 * 60 * 24 * 5 * 1000; 
    const sessionCookie = await adminAuth.createSessionCookie(idToken, { expiresIn });

    const response = NextResponse.json({ success: true }, { status: 200 });

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

export async function DELETE(request: NextRequest) {
  try {
    const session = request.cookies.get('session')?.value;

    if (session) {
      const decodedClaims = await adminAuth.verifySessionCookie(session);
      await adminAuth.revokeRefreshTokens(decodedClaims.sub);
    }

    const response = NextResponse.json({ success: true }, { status: 200 });
    response.cookies.set('session', '', { maxAge: 0, path: '/' });

    return response;
  } catch (error) {
    console.error('Session deletion error', error);
    return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
  }
}
