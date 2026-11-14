import { adminDb } from '@/lib/firebase/admin';
import { AuditLogsClient, AuditLogItem } from './AuditLogsClient';

export const dynamic = 'force-dynamic';

export default async function AuditLogsPage() {
  let logs: AuditLogItem[] = [];

  try {
    const auditQuery = await adminDb.collection('auditLogs')
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();
      
    logs = auditQuery.docs.map((doc) => {
      const d = doc.data();
      return {
        id: doc.id,
        timestamp: d.timestamp ? (d.timestamp.toDate ? d.timestamp.toDate().toISOString() : new Date(d.timestamp).toISOString()) : '',
            action: d.action || 'ACTION NOT RECORDED',
        targetId: d.targetId || '',
            actorId: d.actorId || 'Not recorded',
        reason: d.reason || '',
      };
    });
  } catch (error) {
    console.warn('Could not load audit logs from Firestore.', error);
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-sb-text tracking-tight">
            Audit Ledger & Security
          </h1>
          <p className="text-xs text-sb-text-secondary mt-0.5">
            Administrative and security events recorded in Firestore.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-sb-surface border border-sb-border figma-card-shadow flex items-center gap-2 text-xs font-semibold text-sb-text">
            <span className="w-2 h-2 rounded-full bg-sb-success"></span>
            <span>Firestore audit records</span>
          </div>
        </div>
      </div>

      {/* Audit Log Client View */}
      <AuditLogsClient initialLogs={logs} />
    </div>
  );
}
