import { cookies } from 'next/headers';
import type { NextRequest } from 'next/server';
import { adminAuth } from '@/lib/firebase/admin';

export type AdminRole = 'admin' | 'SUPER_ADMIN' | 'super_admin';

export interface AdminIdentity {
  uid: string;
  email: string;
  name: string;
  role: AdminRole;
}

function isAdminRole(role: unknown): role is AdminRole {
  return role === 'admin' || role === 'SUPER_ADMIN' || role === 'super_admin';
}

function toIdentity(claims: Record<string, unknown> & { uid: string }): AdminIdentity | null {
  const role = claims.role;
  if (!isAdminRole(role)) return null;

  return {
    uid: claims.uid,
    email: typeof claims.email === 'string' ? claims.email : '',
    name: typeof claims.name === 'string' ? claims.name : '',
    role,
  };
}

export async function getAdminSession(): Promise<AdminIdentity | null> {
  const session = (await cookies()).get('session')?.value;
  if (!session) return null;

  try {
    return toIdentity(await adminAuth.verifySessionCookie(session, true));
  } catch {
    return null;
  }
}

export async function getAdminRequestIdentity(
  request: NextRequest,
): Promise<AdminIdentity | null> {
  const session = request.cookies.get('session')?.value;
  if (!session) return null;

  try {
    return toIdentity(await adminAuth.verifySessionCookie(session, true));
  } catch {
    return null;
  }
}

export function isSuperAdmin(identity: AdminIdentity): boolean {
  return identity.role === 'SUPER_ADMIN' || identity.role === 'super_admin';
}
