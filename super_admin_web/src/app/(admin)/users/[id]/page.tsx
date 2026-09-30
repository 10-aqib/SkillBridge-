import { adminAuth, adminDb } from '@/lib/firebase/admin';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { UserClientActions } from './UserClientActions';
import Link from 'next/link';
import { ChevronLeft } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { notFound } from 'next/navigation';

export const dynamic = 'force-dynamic';

export default async function UserDetailPage({ params }: { params: { id: string } }) {
  let userRecord;
  let firestoreData = null;
  let auditLogs: any[] = [];

  try {
    userRecord = await adminAuth.getUser(params.id);
    
    const fsDoc = await adminDb.collection('users').doc(params.id).get();
    if (fsDoc.exists) {
      firestoreData = fsDoc.data();
    }

    const auditQuery = await adminDb.collection('auditLogs')
      .where('targetId', '==', params.id)
      .orderBy('timestamp', 'desc')
      .limit(5)
      .get();
      
    auditLogs = auditQuery.docs.map((doc: any) => ({ id: doc.id, ...doc.data() }));

  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      notFound();
    }
    console.error(error);
  }

  if (!userRecord) return notFound();

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/users">
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
                <Badge variant="default" className="bg-emerald-500">Active</Badge>
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
            <UserClientActions uid={userRecord.uid} isDisabled={userRecord.disabled} />
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
