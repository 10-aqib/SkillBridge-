import { NextRequest, NextResponse } from 'next/server';
import { UsersService } from '@/lib/services/users.service';
import { getAdminRequestIdentity, isSuperAdmin } from '@/lib/auth/admin-session';

export async function POST(request: NextRequest) {
  try {
    const admin = await getAdminRequestIdentity(request);
    if (!admin) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    if (!isSuperAdmin(admin)) {
      return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
    }

    const body = await request.json();
    const { workerId, isVerified } = body;

    if (!workerId || typeof isVerified !== 'boolean') {
      return NextResponse.json({ error: 'Invalid parameters' }, { status: 400 });
    }

    await UsersService.updateWorkerVerification(workerId, isVerified, admin.uid);

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Worker Action Error:', error);
    return NextResponse.json({ error: error instanceof Error ? error.message : 'Internal Server Error' }, { status: 500 });
  }
}
