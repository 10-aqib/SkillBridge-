'use client';

import { useState } from 'react';
import { 
  Search, 
  Clock, 
  UserCheck, 
  Key, 
  Copy, 
  Check,
  Activity,
  Lock
} from 'lucide-react';
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

  const logs = initialLogs;
  const loginEventCount = logs.filter((log) =>
    /LOGIN|SESSION/i.test(log.action),
  ).length;
  const actorCount = new Set(logs.map((log) => log.actorId).filter(Boolean)).size;
  const oldestEvent = logs.reduce<string | null>((oldest, log) => {
    if (!log.timestamp || Number.isNaN(Date.parse(log.timestamp))) return oldest;
    return oldest === null || Date.parse(log.timestamp) < Date.parse(oldest)
      ? log.timestamp
      : oldest;
  }, null);

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
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-sb-success-subtle text-sb-on-success-subtle border border-sb-success/30">
          <UserCheck className="w-3 h-3" />
          {action}
        </span>
      );
    }
    if (action.includes('SESSION') || action.includes('LOGIN') || action.includes('AUTH')) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-sb-primary-subtle text-sb-primary border border-sb-border-strong">
          <Key className="w-3 h-3" />
          {action}
        </span>
      );
    }
    if (action.includes('SECURITY') || action.includes('RULE')) {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-sb-primary-subtle text-sb-on-primary-subtle border border-sb-border-strong">
          <Lock className="w-3 h-3" />
          {action}
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-sb-surface-sunken text-sb-text border border-sb-border">
        <Activity className="w-3 h-3" />
        {action}
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* Top Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Total Audit Records</span>
            <div className="text-2xl font-black text-sb-text mt-1">{logs.length}</div>
            <span className="text-[11px] font-semibold text-sb-primary flex items-center gap-1 mt-0.5">
              Records loaded from Firestore
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-primary-subtle text-sb-primary flex items-center justify-center">
            <Activity className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Recorded Actors</span>
            <div className="text-2xl font-black text-sb-text mt-1">{actorCount}</div>
            <span className="text-[11px] font-semibold text-sb-success flex items-center gap-1 mt-0.5">
              From available audit records
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-success-subtle text-sb-on-success-subtle flex items-center justify-center">
            <UserCheck className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Recorded Login Events</span>
            <div className="text-2xl font-black text-sb-text mt-1">{loginEventCount}</div>
            <span className="text-[11px] font-semibold text-sb-on-primary-subtle flex items-center gap-1 mt-0.5">
              From available audit records
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-primary-subtle text-sb-on-primary-subtle flex items-center justify-center">
            <Lock className="w-5 h-5" />
          </div>
        </div>

        <div className="bg-sb-surface p-5 rounded-2xl border border-sb-border figma-card-shadow flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold text-sb-text-secondary uppercase tracking-wider">Oldest Recorded Event</span>
            <div className="text-2xl font-black text-sb-text mt-1">{oldestEvent ? new Date(oldestEvent).toLocaleDateString() : 'No records'}</div>
            <span className="text-[11px] font-semibold text-sb-text-secondary flex items-center gap-1 mt-0.5">
              Based on available audit records
            </span>
          </div>
          <div className="w-11 h-11 rounded-2xl bg-sb-surface-sunken text-sb-text-secondary flex items-center justify-center">
            <Clock className="w-5 h-5" />
          </div>
        </div>
      </div>

      {/* Main Table Card (Figma Style) */}
      <div className="bg-sb-surface rounded-2xl border border-sb-border figma-card-shadow overflow-hidden">
        {/* Table Filter / Search Header */}
        <div className="p-4 border-b border-sb-border flex flex-col md:flex-row md:items-center justify-between gap-3">
          <div className="relative flex-1 max-w-sm">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-sb-text-secondary" />
            <input 
              type="text"
              placeholder="Search audit actions, actors, reasons..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full h-9 pl-9 pr-3 rounded-xl bg-sb-canvas border-none text-xs text-sb-text placeholder:text-sb-text-secondary focus:outline-none focus:ring-2 focus:ring-sb-focus/30 transition"
            />
          </div>

          <div className="flex items-center gap-1 bg-sb-canvas p-1 rounded-xl">
            {['all', 'verification', 'session', 'security'].map((filter) => (
              <button
                key={filter}
                onClick={() => setSelectedAction(filter)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold capitalize transition ${
                  selectedAction === filter 
                    ? 'bg-sb-surface text-sb-primary shadow-sm font-bold' 
                    : 'text-sb-text-secondary hover:text-sb-text'
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
            <thead className="bg-sb-canvas text-sb-text-secondary font-semibold uppercase tracking-wider text-[11px] border-b border-sb-border">
              <tr>
                <th className="px-6 py-3.5">Timestamp</th>
                <th className="px-6 py-3.5">Action Executed</th>
                <th className="px-6 py-3.5">Actor (Super Admin)</th>
                <th className="px-6 py-3.5">Target Entity</th>
                <th className="px-6 py-3.5">Reason & Description</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-sb-border text-sb-text font-medium">
              {filteredLogs.map((log) => (
                <tr key={log.id} className="hover:bg-sb-canvas transition duration-150">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className="font-semibold text-sb-text block">
                      {log.timestamp ? new Date(log.timestamp).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                      }) : 'Time not recorded'}
                    </span>
                    <span className="text-[11px] text-sb-text-secondary block font-mono">
                      {log.timestamp ? new Date(log.timestamp).toLocaleTimeString('en-US', {
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit'
                      }) : ''}
                    </span>
                  </td>

                  <td className="px-6 py-4">
                    {getActionBadge(log.action)}
                  </td>

                  <td className="px-6 py-4">
                    <span className="font-semibold text-sb-text block text-xs truncate max-w-[200px]">
                      {log.actorId || 'Not recorded'}
                    </span>
                      <span className="text-[10px] text-sb-text-secondary">Recorded actor</span>
                  </td>

                  <td className="px-6 py-4">
                    {log.targetId ? (
                      <div className="flex items-center gap-1.5 font-mono text-[11px] bg-sb-canvas px-2 py-1 rounded-md max-w-fit border border-sb-border">
                        <span className="text-sb-text-secondary truncate max-w-[140px]">{log.targetId}</span>
                        <button
                          onClick={() => copyToClipboard(log.targetId!, log.id)}
                          className="text-sb-text-secondary hover:text-sb-text-secondary"
                        >
                          {copiedId === log.id ? (
                            <Check className="w-3 h-3 text-sb-success" />
                          ) : (
                            <Copy className="w-3 h-3" />
                          )}
                        </button>
                      </div>
                    ) : (
                      <span className="text-sb-text-secondary italic">N/A</span>
                    )}
                  </td>

                  <td className="px-6 py-4">
                    <span className="text-sb-text-secondary text-xs block max-w-md">
                      {log.reason || 'No additional audit notes recorded.'}
                    </span>
                  </td>
                </tr>
              ))}

              {filteredLogs.length === 0 && (
                <tr>
                  <td colSpan={5} className="py-12 text-center text-sb-text-secondary">
                    <p className="font-medium text-sm text-sb-text-secondary">No matching audit logs found</p>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>

        {/* Table Footer */}
        <div className="p-4 border-t border-sb-border flex items-center justify-between text-xs text-sb-text-secondary">
          <span>Displaying {filteredLogs.length} audit records</span>
          <span className="text-[11px] font-medium text-sb-on-success-subtle flex items-center gap-1">
            <Activity className="w-3.5 h-3.5" /> Audit entries from Firestore
          </span>
        </div>
      </div>
    </div>
  );
}
