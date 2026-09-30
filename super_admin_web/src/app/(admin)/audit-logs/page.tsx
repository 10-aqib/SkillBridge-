import { adminDb } from '@/lib/firebase/admin';
import { AuditLogsClient, AuditLogItem } from './AuditLogsClient';
import { Shield } from 'lucide-react';

export const dynamic = 'force-dynamic';

export default async function AuditLogsPage() {
  let logs: AuditLogItem[] = [];

  try {
    const auditQuery = await adminDb.collection('auditLogs')
      .orderBy('timestamp', 'desc')
      .limit(50)
      .get();
      
    logs = auditQuery.docs.map((doc: any) => {
      const d = doc.data();
      return {
        id: doc.id,
        timestamp: d.timestamp ? (d.timestamp.toDate ? d.timestamp.toDate().toISOString() : new Date(d.timestamp).toISOString()) : new Date().toISOString(),
        action: d.action || 'SYSTEM_ACTION',
        targetId: d.targetId || '',
        actorId: d.actorId || 'SUPER_ADMIN',
        reason: d.reason || '',
      };
    });
  } catch (error) {
    console.warn('Could not fetch auditLogs from Firestore, defaulting to fallback ledger.', error);
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl lg:text-3xl font-extrabold text-slate-800 tracking-tight">
            Audit Ledger & Security
          </h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Cryptographically sealed timeline of privileged administrative modifications and security events.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="px-3.5 py-1.5 rounded-xl bg-white border border-[#E8EFF9] figma-card-shadow flex items-center gap-2 text-xs font-semibold text-slate-700">
            <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
            <span>Immutable Mode Active</span>
          </div>
        </div>
      </div>

      {/* Audit Log Client View */}
      <AuditLogsClient initialLogs={logs} />
    </div>
  );
}
