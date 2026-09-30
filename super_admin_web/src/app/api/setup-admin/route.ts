import { adminAuth } from '@/lib/firebase/admin';
import { NextRequest, NextResponse } from 'next/server';

export async function POST(req: NextRequest) {
  try {
    const { email, secret } = await req.json();

    if (secret !== process.env.SETUP_SECRET) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    if (!email) {
      return NextResponse.json({ error: 'Email is required' }, { status: 400 });
    }

    const user = await adminAuth.getUserByEmail(email);
    
    await adminAuth.setCustomUserClaims(user.uid, {
      role: 'SUPER_ADMIN',
    });

    return NextResponse.json({ success: true, message: `Successfully made ${email} a SUPER_ADMIN.` });
  } catch (error: any) {
    console.error('Error setting custom claims:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
