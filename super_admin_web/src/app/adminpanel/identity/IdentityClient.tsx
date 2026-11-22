'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AlertTriangle, CheckCircle2, Clock3, Fingerprint, FlaskConical, Search, XCircle } from 'lucide-react';
import type { IdentityRequestItem } from '@/lib/services/identity.service';

const IN_PROGRESS = new Set(['pending', 'consent_pending', 'capturing', 'submitted', 'processing']);
const FAILED = new Set(['rejected', 'failed']);
const CLOSED = new Set(['cancelled', 'expired']);

const filters = [
  { key: 'all', label: 'All' },
  { key: 'progress', label: 'In progress' },
  { key: 'verified', label: 'Verified (NADRA)' },
  { key: 'test', label: 'Test results' },
  { key: 'failed', label: 'Rejected / failed' },
  { key: 'manual_review', label: 'Manual review' },
  { key: 'closed', label: 'Cancelled / expired' },
] as const;

function matches(r: IdentityRequestItem, f: string) {
  switch (f) {
    case 'progress': return IN_PROGRESS.has(r.status);
    case 'verified': return r.status === 'verified' && !r.test;
    case 'test': return r.test;
    case 'failed': return FAILED.has(r.status);
    case 'manual_review': return r.status === 'manual_review';
    case 'closed': return CLOSED.has(r.status);
    default: return true;
  }
}

function statusLabel(r: IdentityRequestItem) {
  if (r.status === 'verified') return r.test ? 'TEST pass (not real)' : 'NADRA verified';
  return r.status.replace(/_/g, ' ');
}

export function IdentityClient({ initialRequests }: { initialRequests: IdentityRequestItem[] }) {
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState<string>('all');
  const [busy, setBusy] = useState<string | null>(null);
  const [error, setError] = useState('');

  const rows = useMemo(() => initialRequests.filter((r) => {
    const q = query.trim().toLowerCase();
    const hit = !q || [r.id, r.userId, r.userName, r.transactionReference, r.maskedCnic].some((v) => v.toLowerCase().includes(q));
    return hit && matches(r, filter);
  }), [initialRequests, query, filter]);

  const count = (f: string) => initialRequests.filter((r) => matches(r, f)).length;

  async function act(r: IdentityRequestItem, action: 'manual_review' | 'request_retry') {
    const note = window.prompt(action === 'manual_review' ? 'Reason for additional review (kept in the audit log):' : 'Message reason for asking the person to verify again (kept in the audit log):') ?? undefined;
    if (note === undefined) return;
    setBusy(r.id);
    setError('');
    try {
      const response = await fetch('/api/admin/identity/action', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ sessionId: r.id, action, note }),
      });
      const result = await response.json();
      if (!response.ok) throw new Error(result.error || 'The request could not be updated.');
      router.refresh();
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : 'The request could not be updated.');
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-5">
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {[
          { label: 'Total requests', value: count('all'), icon: Fingerprint, color: 'text-sb-primary bg-sb-primary-subtle' },
          { label: 'In progress', value: count('progress'), icon: Clock3, color: 'text-sb-on-primary-subtle bg-sb-primary-subtle' },
          { label: 'NADRA verified', value: count('verified'), icon: CheckCircle2, color: 'text-sb-on-success-subtle bg-sb-success-subtle' },
          { label: 'Rejected / failed', value: count('failed'), icon: XCircle, color: 'text-sb-on-warning-subtle bg-sb-warning-subtle' },
          { label: 'Manual review', value: count('manual_review'), icon: AlertTriangle, color: 'text-sb-on-warning-subtle bg-sb-warning-subtle' },
          { label: 'Cancelled / expired', value: count('closed'), icon: Clock3, color: 'text-sb-text-secondary bg-sb-surface' },
          { label: 'Test (simulator)', value: count('test'), icon: FlaskConical, color: 'text-sb-on-warning-subtle bg-sb-warning-subtle' },
        ].map(({ label, value, icon: Icon, color }) => (
          <article key={label} className="rounded-2xl border border-sb-border bg-sb-surface p-4 shadow-sm sm:p-5">
            <div className="flex items-center justify-between">
              <p className="text-sm font-medium text-sb-text-secondary">{label}</p>
              <span className={`flex h-9 w-9 items-center justify-center rounded-xl ${color}`}><Icon className="h-4 w-4" /></span>
            </div>
            <p className="mt-3 text-2xl font-extrabold text-sb-text">{value}</p>
          </article>
        ))}
      </section>

      <section className="flex flex-col gap-3 md:flex-row md:items-center">
        <label className="relative flex-1">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-sb-text-secondary" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by request, user, reference or masked CNIC"
            className="w-full rounded-xl border border-sb-border bg-sb-surface py-2 pl-9 pr-3 text-sm text-sb-text"
          />
        </label>
        <div className="flex flex-wrap gap-2">
          {filters.map((f) => (
            <button
              key={f.key}
              type="button"
              onClick={() => setFilter(f.key)}
              className={`rounded-full border px-3 py-1 text-xs font-semibold ${filter === f.key ? 'border-sb-primary bg-sb-primary-subtle text-sb-primary' : 'border-sb-border text-sb-text-secondary'}`}
            >
              {f.label} ({count(f.key)})
            </button>
          ))}
        </div>
      </section>

      {error && <p role="alert" className="rounded-xl border border-sb-border bg-sb-warning-subtle px-3 py-2 text-sm text-sb-on-warning-subtle">{error}</p>}

      <section className="overflow-x-auto rounded-2xl border border-sb-border bg-sb-surface">
        <table className="w-full min-w-[900px] text-left text-sm">
          <thead className="text-xs uppercase text-sb-text-secondary">
            <tr>
              <th className="px-4 py-3">Requested</th>
              <th className="px-4 py-3">User</th>
              <th className="px-4 py-3">Role</th>
              <th className="px-4 py-3">CNIC (masked)</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3">Technical category</th>
              <th className="px-4 py-3">Provider reference</th>
              <th className="px-4 py-3">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr><td colSpan={8} className="px-4 py-6 text-center text-sb-text-secondary">No verification requests match.</td></tr>
            )}
            {rows.map((r) => (
              <tr key={r.id} className="border-t border-sb-border align-top">
                <td className="px-4 py-3 whitespace-nowrap">{r.createdAt ? new Date(r.createdAt).toLocaleString() : '—'}</td>
                <td className="px-4 py-3">
                  <div className="font-semibold text-sb-text">{r.userName || '—'}</div>
                  <div className="text-xs text-sb-text-secondary">{r.userId}</div>
                </td>
                <td className="px-4 py-3">{r.userRole === 'client' ? 'Hirer' : r.userRole === 'worker' ? 'Worker' : r.userRole}</td>
                <td className="px-4 py-3 font-mono">{r.maskedCnic}</td>
                <td className="px-4 py-3">
                  <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${r.test ? 'bg-sb-warning-subtle text-sb-on-warning-subtle' : r.status === 'verified' ? 'bg-sb-success-subtle text-sb-on-success-subtle' : 'bg-sb-primary-subtle text-sb-on-primary-subtle'}`}>
                    {statusLabel(r)}
                  </span>
                  <div className="mt-1 text-xs text-sb-text-secondary">{r.test ? 'Simulator (test only)' : r.provider} · attempts {r.attempts}</div>
                </td>
                <td className="px-4 py-3 text-xs">{r.failureCategory ? r.failureCategory.replace(/_/g, ' ') : '—'}</td>
                <td className="px-4 py-3 font-mono text-xs">{r.transactionReference || '—'}</td>
                <td className="px-4 py-3">
                  <div className="flex flex-col gap-1">
                    {['pending', 'rejected', 'failed', 'expired'].includes(r.status) && (
                      <button type="button" disabled={busy === r.id} onClick={() => act(r, 'manual_review')}
                        className="rounded-lg border border-sb-border px-2 py-1 text-xs font-semibold text-sb-text disabled:opacity-50">
                        Mark for review
                      </button>
                    )}
                    {['rejected', 'failed', 'manual_review', 'expired'].includes(r.status) && (
                      <button type="button" disabled={busy === r.id} onClick={() => act(r, 'request_retry')}
                        className="rounded-lg border border-sb-border px-2 py-1 text-xs font-semibold text-sb-text disabled:opacity-50">
                        Ask to verify again
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>
      <p className="text-xs text-sb-text-secondary">
        There is no way to mark someone NADRA verified here. Only an authentic NADRA result can do that. Suspend
        suspicious accounts from Users. Every action is recorded in Audit Logs.
      </p>
    </div>
  );
}
