import { adminAuth } from '@/lib/firebase/admin';
import { NextRequest, NextResponse } from 'next/server';
import { timingSafeEqual } from 'node:crypto';

export async function POST(req: NextRequest) {
  try {
    const { email, secret } = await req.json();
    const setupSecret = process.env.SETUP_SECRET;

    if (!setupSecret || typeof secret !== 'string' ||
        Buffer.byteLength(secret) !== Buffer.byteLength(setupSecret) ||
        !timingSafeEqual(Buffer.from(secret), Buffer.from(setupSecret))) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    if (typeof email !== 'string' || !email.trim()) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const user = await adminAuth.getUserByEmail(email.trim());
    
    await adminAuth.setCustomUserClaims(user.uid, {
      role: 'SUPER_ADMIN',
    });

    return NextResponse.json({ success: true, message: 'Administrator role updated.' });
  } catch (error) {
    console.error('Error setting custom claims:', error);
    return NextResponse.json({ error: error instanceof Error ? error.message : 'Internal Server Error' }, { status: 500 });
  }
}
