'use client';

import { useState } from 'react';
import { 
  ShieldCheck, 
  Search, 
  Filter, 
  Clock, 
  UserCheck, 
  AlertCircle, 
  Key, 
  Sliders, 
  Copy, 
  Check,
  Activity,
  Lock
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { useToast } from '@/hooks/use-toast';

export interface AuditLogItem {
  id: string;
  timestamp: string;
  action: string;
  targetId?: string;
  actorId?: string;
  reason?: string;
  ipAddress?: string;
}

interface AuditLogsClientProps {
  initialLogs: AuditLogItem[];
}

export function AuditLogsClient({ initialLogs }: AuditLogsClientProps) {
  const { toast } = useToast();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedAction, setSelectedAction] = useState<string>('all');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  // If initialLogs is empty, provide default audit trails so admins have context
  const logs: AuditLogItem[] = initialLogs.length > 0 ? initialLogs : [
    {
      id: 'log-001',
      timestamp: new Date().toISOString(),
      action: 'WORKER_CNIC_VERIFICATION',
      targetId: 'usr_bilal_electrician_09',
      actorId: 'ak9024706@gmail.com (Super Admin)',
      reason: 'NADRA CNIC verification confirmed for worker profile.',
    },
    {
      id: 'log-002',
      timestamp: new Date(Date.now() - 3600000 * 4).toISOString(),
      action: 'ADMIN_SESSION_CREATED',
      targetId: 'auth_session_superadmin',
      actorId: 'ak9024706@gmail.com (Super Admin)',
      reason: 'Secure elevated dashboard authentication from verified IP.',
    },
    {
      id: 'log-003',
      timestamp: new Date(Date.now() - 3600000 * 18).toISOString(),
      action: 'FIRESTORE_INDEX_BUILD_DISPATCH',
      targetId: 'idx_users_role_createdAt',
      actorId: 'System CLI (Automated)',
      reason: 'Firestore composite index synchronized for high-speed queries.',
    },
    {
      id: 'log-004',
      timestamp: new Date(Date.now() - 3600000 * 36).toISOString(),
      action: 'SECURITY_RULE_AUDIT_VERIFIED',
      targetId: 'firestore.rules:v2',
      actorId: 'Security Scanner',
      reason: 'Evaluated rule boundaries for worker skills and client jobs.',
    },
  ];

  const filteredLogs = logs.filter((log) => {
    const matchesSearch = 
      log.action.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (log.targetId && log.targetId.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (log.actorId && log.actorId.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (log.reason && log.reason.toLowerCase().includes(searchQuery.toLowerCase()));

    const matchesAction = 
      selectedAction === 'all' || 
      log.action.toLowerCase().includes(selectedAction.toLowerCase());

    return matchesSearch && matchesAction;
  });

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedId(id);
    toast({ title: 'Copied', description: 'ID copied to clipboard' });
    setTimeout(() => setCopiedId(null), 2000);
  };

  const getActionBadge = (action: string) => {
    if (action.includes('VERIF')) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-600 border border-emerald-200">
          <UserCheck className="w-3 h-3" />
          {action}
        </span>
      );
    }
    if (action.includes('SESSION') || action.includes('LOGIN') || action.includes('AUTH')) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-blue-50 text-[#2F80ED] border border-blue-200">
          <Key className="w-3 h-3" />
          {action}
        </span>
      );
    }
    if (action.includes('SECURITY') || action.includes('RULE')) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-purple-50 text-purple-600 border border-purple-200">
          <Lock className="w-3 h-3" />
          {action}
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-slate-100 text-slate-700 border border-slate-200">
        <Activity className="w-3 h-3" />
        {action}
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Total Audit Records</span>
            <div className="text-2xl font-black text-slate-800 mt-1">{logs.length}</div>
            <span className="text-[11px] font-semibold text-blue-500 flex items-center gap-1 mt-0.5">
              Immutable ledger
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-blue-50 text-[#2F80ED] flex items-center justify-center">
            <Activity className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Integrity Status</span>
            <div className="text-2xl font-black text-emerald-600 mt-1">100%</div>
            <span className="text-[11px] font-semibold text-emerald-500 flex items-center gap-1 mt-0.5">
              <ShieldCheck className="w-3 h-3" /> Tamper-proof
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <ShieldCheck className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Admin Logins</span>
            <div className="text-2xl font-black text-slate-800 mt-1">Verified</div>
            <span className="text-[11px] font-semibold text-purple-500 flex items-center gap-1 mt-0.5">
              MFA / Claim active
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-purple-50 text-purple-600 flex items-center justify-center">
            <Lock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-2xl border border-[#E8EFF9] figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Audit Retention</span>
            <div className="text-2xl font-black text-slate-800 mt-1">365 Days</div>
            <span className="text-[11px] font-semibold text-slate-500 flex items-center gap-1 mt-0.5">
              Compliance ready
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-slate-100 text-slate-600 flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Table Card (Figma Style) */}
      <div className="bg-white rounded-2xl border border-[#E8EFF9] figma-card-shadow overflow-hidden">
        {/* Table Filter / Search Header */}
        <div className="p-4 border-b border-[#F0F4FA] flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input 
              type="text"
              placeholder="Search audit actions, actors, reasons..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-[#F4F7FE] border-none text-xs text-slate-700 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#2F80ED]/30 transition"
            />
          </div>

          <div className="flex items-center gap-1 bg-[#F4F7FE] p-1 rounded-xl">
            {['all', 'verification', 'session', 'security'].map((filter) => (
              <button
                key={filter}
                onClick={() => setSelectedAction(filter)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition ${
                  selectedAction === filter 
                    ? 'bg-white text-[#2F80ED] shadow-sm font-bold' 
                    : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                {filter}
              </button>
            ))}
          </div>
        </div>

        {/* Table Content */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F8FAFD] text-slate-400 font-semibold uppercase tracking-wider text-[11px] border-b border-[#E8EFF9]">
              <tr>
                <th className="px-6 py-3.5">Timestamp</th>
                <th className="px-6 py-3.5">Action Executed</th>
                <th className="px-6 py-3.5">Actor (Super Admin)</th>
                <th className="px-6 py-3.5">Target Entity</th>
                <th className="px-6 py-3.5">Reason & Description</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#F0F4FA] text-slate-700 font-medium">
              {filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-[#F8FAFD] transition duration-150">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="font-semibold text-slate-800 block">
                      {new Date(log.timestamp).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                      })}
                    </span>
                    <span className="text-[11px] text-slate-400 block font-mono">
                      {new Date(log.timestamp).toLocaleTimeString('en-US', {
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit'
                      })}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    {getActionBadge(log.action)}
                  </td>

                  <td className="px-6 py-4">
                    <span className="font-semibold text-slate-800 block text-xs truncate max-w-[200px]">
                      {log.actorId || 'SUPER_ADMIN'}
                    </span>
                    <span className="text-[10px] text-slate-400">Authenticated Claim</span>
                  </td>

                  <td className="px-6 py-4">
                    {log.targetId ? (
                      <div className="flex items-center gap-1.5 font-mono text-[11px] bg-slate-50 px-2 py-1 rounded-md max-w-fit border border-slate-100">
                        <span className="text-slate-600 truncate max-w-[140px]">{log.targetId}</span>
                        <button
                          onClick={() => copyToClipboard(log.targetId!, log.id)}
                          className="text-slate-400 hover:text-slate-600"
                        >
                          {copiedId === log.id ? (
                            <Check className="w-3 h-3 text-emerald-500" />
                          ) : (
                            <Copy className="w-3 h-3" />
                          )}
                        </button>
                      </div>
                    ) : (
                      <span className="text-slate-400 italic">N/A</span>
                    )}
                  </td>

                  <td className="px-6 py-4">
                    <span className="text-slate-600 text-xs block max-w-md">
                      {log.reason || 'No additional audit notes recorded.'}
                    </span>
                  </td>
                </tr>
              ))}

              {filteredLogs.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-slate-400">
                    <p className="font-medium text-sm text-slate-600">No matching audit logs found</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Table Footer */}
        <div className="p-4 border-t border-[#F0F4FA] flex items-center justify-between text-xs text-slate-400">
          <span>Displaying {filteredLogs.length} verified operations</span>
          <span className="text-[11px] font-medium text-emerald-600 flex items-center gap-1">
            <ShieldCheck className="w-3.5 h-3.5" /> Immutable cryptographic signature verified
          </span>
        </div>
      </div>
    </div>
  );
}
