import { adminAuth, adminDb } from '@/lib/firebase/admin';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { UserClientActions } from './UserClientActions';
import Link from 'next/link';
import { ChevronLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { notFound } from 'next/navigation';
import { getAdminSession, isSuperAdmin } from '@/lib/auth/admin-session';

export const dynamic = 'force-dynamic';

export default async function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const admin = await getAdminSession();
  if (!admin) return null;
  let userRecord;
  let firestoreData = null;
  let auditLogs: Array<{
    id: string;
    action: string;
    reason: string;
    timestamp: string;
    actorId: string;
  }> = [];

  try {
    userRecord = await adminAuth.getUser(id);
    
    const fsDoc = await adminDb.collection('users').doc(id).get();
    if (fsDoc.exists) {
      firestoreData = fsDoc.data();
    }

    const auditQuery = await adminDb.collection('auditLogs')
      .where('targetId', '==', id)
      .orderBy('timestamp', 'desc')
      .limit(5)
      .get();
      
    auditLogs = auditQuery.docs.map((doc) => {
      const data = doc.data();
      const timestamp = data.timestamp;
      return {
        id: doc.id,
        action: typeof data.action === 'string' ? data.action : 'ACTION NOT RECORDED',
        reason: typeof data.reason === 'string' ? data.reason : '',
        timestamp: timestamp?.toDate
          ? timestamp.toDate().toISOString()
          : typeof timestamp === 'string' ? timestamp : '',
        actorId: typeof data.actorId === 'string' ? data.actorId : 'Not recorded',
      };
    });

  } catch (error) {
    const errorCode = typeof error === 'object' && error !== null && 'code' in error
      ? error.code
      : undefined;
    if (errorCode === 'auth/user-not-found') {
      notFound();
    }
    console.error(error);
  }

  if (!userRecord) return notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/adminpanel/users">
          <Button variant="outline" size="icon">
            <ChevronLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h2 className="text-3xl font-bold tracking-tight">User Details</h2>
          <p className="text-muted-foreground">{userRecord.email}</p>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Profile Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">ID</span>
              <span className="font-mono text-sm">{userRecord.uid}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">Name</span>
              <span>{userRecord.displayName || firestoreData?.name || 'N/A'}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">Email</span>
              <span>{userRecord.email}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">Phone</span>
              <span>{userRecord.phoneNumber || firestoreData?.phone || 'N/A'}</span>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">Role</span>
              <Badge variant="outline" className="capitalize">{firestoreData?.role || 'client'}</Badge>
            </div>
            <div className="flex justify-between border-b pb-2">
              <span className="font-medium text-muted-foreground">Status</span>
              {userRecord.disabled ? (
                <Badge variant="destructive">Suspended</Badge>
              ) : (
                <Badge variant="default" className="bg-sb-success">Active</Badge>
              )}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Administrative Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            <p className="text-sm text-muted-foreground">
              Take administrative action on this user. Please note that suspending a user will revoke their current sessions and prevent future logins.
            </p>
            {isSuperAdmin(admin) && admin.uid !== userRecord.uid ? (
              <UserClientActions uid={userRecord.uid} isDisabled={userRecord.disabled} />
            ) : (
              <p className="text-sm text-muted-foreground">
                {admin.uid === userRecord.uid
                  ? 'You cannot suspend or delete your own administrator account.'
                  : 'Only a super administrator can change account access.'}
              </p>
            )}
          </CardContent>
        </Card>

        <Card className="md:col-span-2">
          <CardHeader>
            <CardTitle>Recent Audit Logs</CardTitle>
          </CardHeader>
          <CardContent>
            {auditLogs.length > 0 ? (
              <div className="space-y-4">
                {auditLogs.map(log => (
                  <div key={log.id} className="flex justify-between items-center border-b pb-2 last:border-0">
                    <div>
                      <p className="font-medium">{log.action}</p>
                      <p className="text-sm text-muted-foreground">Reason: {log.reason}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-muted-foreground">{new Date(log.timestamp).toLocaleString()}</p>
                      <p className="text-xs text-muted-foreground font-mono">By: {log.actorId}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-sm text-muted-foreground">No recent administrative actions found.</p>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
