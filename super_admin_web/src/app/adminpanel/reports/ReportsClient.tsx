'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AlertTriangle, CheckCircle2, Clock3, Search, ShieldAlert } from 'lucide-react';

export interface ReportItem {
  id: string;
  reporterId: string;
  reporterName: string;
  targetUserId: string;
  targetName: string;
  targetType: string;
  reason: string;
  status: string;
  moderationNote: string;
  createdAt: string;
}

const statuses = ['all', 'open', 'investigating', 'resolved'] as const;

export function ReportsClient({ initialReports }: { initialReports: ReportItem[] }) {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [savingId, setSavingId] = useState<string | null>(null);
  const [error, setError] = useState('');

  const reports = useMemo(() => initialReports.filter((report) => {
    const normalizedQuery = query.trim().toLowerCase();
    const matchesQuery = !normalizedQuery || [
      report.id,
      report.reporterName,
      report.reporterId,
      report.targetName,
      report.targetUserId,
      report.reason,
    ].some((value) => value.toLowerCase().includes(normalizedQuery));
    return matchesQuery && (statusFilter === 'all' || report.status === statusFilter);
  }), [initialReports, query, statusFilter]);

  const count = (status: string) => initialReports.filter((report) =>
    status === 'all' ? true : report.status === status,
  ).length;

  async function updateReport(report: ReportItem, status: string) {
    setSavingId(report.id);
    setError('');
    try {
      const response = await fetch('/api/admin/reports/action', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          reportId: report.id,
          status,
          moderationNote: report.moderationNote,
        }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || 'The report could not be updated.');
      router.refresh();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The report could not be updated.');
    } finally {
      setSavingId(null);
    }
  }

  return (
    <div className="space-y-5">
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[
          { label: 'All reports', value: count('all'), icon: ShieldAlert, color: 'text-sb-primary bg-sb-primary-subtle' },
          { label: 'Open', value: count('open'), icon: AlertTriangle, color: 'text-sb-on-warning-subtle bg-sb-warning-subtle' },
          { label: 'Investigating', value: count('investigating'), icon: Clock3, color: 'text-sb-on-primary-subtle bg-sb-primary-subtle' },
          { label: 'Resolved', value: count('resolved'), icon: CheckCircle2, color: 'text-sb-on-success-subtle bg-sb-success-subtle' },
        ].map(({ label, value, icon: Icon, color }) => (
          <article key={label} className="rounded-2xl border border-sb-border bg-sb-surface p-4 shadow-sm sm:p-5">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-sb-text-secondary">{label}</p>
              <span className={`rounded-xl p-2 ${color}`}><Icon className="h-4 w-4" /></span>
            </div>
            <p className="mt-3 text-2xl font-bold tracking-tight text-sb-text">{value}</p>
          </article>
        ))}
      </section>

      <section className="overflow-hidden rounded-2xl border border-sb-border bg-sb-surface shadow-sm">
        <div className="flex flex-col gap-3 border-b border-sb-border p-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="font-semibold text-sb-text">User reports</h2>
            <p className="mt-0.5 text-xs text-sb-text-secondary">Records loaded from the app’s Firestore reports collection.</p>
          </div>
          <div className="flex flex-col gap-2 sm:flex-row">
            <label className="relative block sm:w-64">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-sb-text-secondary" />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search reports or accounts"
                className="h-10 w-full rounded-xl border border-sb-border bg-sb-surface pl-9 pr-3 text-sm outline-none transition focus:border-sb-focus focus:ring-2 focus:ring-sb-focus/20"
              />
            </label>
            <select
              value={statusFilter}
              onChange={(event) => setStatusFilter(event.target.value)}
              aria-label="Filter reports by status"
              className="h-10 rounded-xl border border-sb-border bg-sb-surface px-3 text-sm text-sb-text outline-none focus:border-sb-focus focus:ring-2 focus:ring-sb-focus/20"
            >
              {statuses.map((status) => <option key={status} value={status}>{status === 'all' ? 'All statuses' : status}</option>)}
            </select>
          </div>
        </div>

        {error && <p role="alert" className="border-b border-sb-error/20 bg-sb-error-subtle px-4 py-3 text-sm text-sb-error">{error}</p>}

        <div className="overflow-x-auto">
          <table className="w-full min-w-[850px] text-left text-sm">
            <thead className="bg-sb-canvas text-[11px] uppercase tracking-wide text-sb-text-secondary">
              <tr>
                <th className="px-5 py-3 font-semibold">Report</th>
                <th className="px-5 py-3 font-semibold">Reporter</th>
                <th className="px-5 py-3 font-semibold">Reported account</th>
                <th className="px-5 py-3 font-semibold">Reason</th>
                <th className="px-5 py-3 font-semibold">Status</th>
                <th className="px-5 py-3 text-right font-semibold">Moderation</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-sb-border">
              {reports.map((report) => (
                <tr key={report.id} className="align-top hover:bg-sb-canvas/70">
                  <td className="px-5 py-4">
                    <p className="font-mono text-xs text-sb-text">{report.id.slice(0, 12)}</p>
                    <p className="mt-1 text-xs text-sb-text-secondary">{report.createdAt ? new Date(report.createdAt).toLocaleString() : 'Date unavailable'}</p>
                  </td>
                  <td className="px-5 py-4">
                    <p className="font-medium text-sb-text">{report.reporterName}</p>
                    <p className="mt-1 font-mono text-[11px] text-sb-text-secondary">{report.reporterId.slice(0, 10)}</p>
                  </td>
                  <td className="px-5 py-4">
                    <p className="font-medium text-sb-text">{report.targetName}</p>
                    <p className="mt-1 text-xs capitalize text-sb-text-secondary">{report.targetType.replaceAll('_', ' ')}</p>
                  </td>
                  <td className="max-w-xs whitespace-normal px-5 py-4 text-sb-text-secondary">{report.reason}</td>
                  <td className="px-5 py-4">
                    <span className="rounded-full bg-sb-surface-sunken px-2.5 py-1 text-xs font-medium capitalize text-sb-text">{report.status}</span>
                    {report.moderationNote && <p className="mt-2 max-w-48 text-xs text-sb-text-secondary">{report.moderationNote}</p>}
                  </td>
                  <td className="px-5 py-4 text-right">
                    <div className="flex justify-end gap-2">
                      {report.status !== 'investigating' && report.status !== 'resolved' && (
                        <button disabled={savingId === report.id} onClick={() => updateReport(report, 'investigating')} className="rounded-lg border border-sb-border px-2.5 py-1.5 text-xs font-semibold text-sb-text-secondary hover:bg-sb-canvas disabled:opacity-50">
                          Investigate
                        </button>
                      )}
                      {report.status !== 'resolved' ? (
                        <button disabled={savingId === report.id} onClick={() => updateReport(report, 'resolved')} className="rounded-lg bg-sb-primary px-2.5 py-1.5 text-xs font-semibold text-sb-on-primary hover:bg-sb-primary-hover disabled:opacity-50">
                          {savingId === report.id ? 'Saving…' : 'Resolve'}
                        </button>
                      ) : (
                        <button disabled={savingId === report.id} onClick={() => updateReport(report, 'open')} className="rounded-lg border border-sb-border px-2.5 py-1.5 text-xs font-semibold text-sb-text-secondary hover:bg-sb-canvas disabled:opacity-50">
                          Reopen
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {reports.length === 0 && (
                <tr><td colSpan={6} className="px-5 py-14 text-center">
                  <ShieldAlert className="mx-auto h-8 w-8 text-sb-text-disabled" />
                  <p className="mt-3 font-medium text-sb-text">No reports have been submitted</p>
                  <p className="mt-1 text-sm text-sb-text-secondary">New app reports will appear here for review.</p>
                </td></tr>
              )}
              {reports.length > 0 && reports.filter((report) => {
                const normalizedQuery = query.trim().toLowerCase();
                const matchesQuery = !normalizedQuery || [report.id, report.reporterName, report.reporterId, report.targetName, report.targetUserId, report.reason].some((value) => value.toLowerCase().includes(normalizedQuery));
                return matchesQuery && (statusFilter === 'all' || report.status === statusFilter);
              }).length === 0 && (
                <tr><td colSpan={6} className="px-5 py-12 text-center text-sm text-sb-text-secondary">No reports match these filters.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
