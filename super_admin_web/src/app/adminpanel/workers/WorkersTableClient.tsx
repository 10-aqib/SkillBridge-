'use client';

import { useMemo, useState } from 'react';
import { Search, ShieldCheck, Star, MapPin } from 'lucide-react';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { WorkerClientActions } from './WorkerClientActions';

export interface WorkerRow {
  uid: string;
  email: string;
  displayName: string;
  isActive: boolean;
  isVerified: boolean;
  skills: string[];
  city: string;
  rating: number;
  completedJobs: number;
  createdAt: string;
}

export function WorkersTableClient({ workers, canVerify }: { workers: WorkerRow[]; canVerify: boolean }) {
  const [query, setQuery] = useState('');
  const [verification, setVerification] = useState('all');
  const visibleWorkers = useMemo(() => workers.filter((worker) => {
    const normalizedQuery = query.trim().toLowerCase();
    const matchesQuery = !normalizedQuery || [worker.displayName, worker.email, worker.city, ...worker.skills]
      .some((value) => value.toLowerCase().includes(normalizedQuery));
    return matchesQuery && (verification === 'all' || (verification === 'verified' ? worker.isVerified : !worker.isVerified));
  }), [workers, query, verification]);

  return (
    <section className="overflow-hidden rounded-2xl border border-sb-border bg-sb-surface shadow-sm">
      <div className="flex flex-col gap-3 border-b border-sb-border p-4 lg:flex-row lg:items-center lg:justify-between">
        <div><h2 className="font-semibold text-sb-text">Worker accounts</h2><p className="mt-0.5 text-xs text-sb-text-secondary">Search the latest {workers.length} worker profiles by name, city, or skill.</p></div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <label className="relative sm:w-72"><Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-sb-text-secondary" /><input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search workers" className="h-10 w-full rounded-xl border border-sb-border pl-9 pr-3 text-sm outline-none focus:border-sb-focus focus:ring-2 focus:ring-sb-focus/20" /></label>
          <select value={verification} onChange={(event) => setVerification(event.target.value)} aria-label="Filter workers by verification" className="h-10 rounded-xl border border-sb-border bg-sb-surface px-3 text-sm outline-none focus:border-sb-focus"><option value="all">All verification states</option><option value="pending">Pending review</option><option value="verified">Verified</option></select>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[900px] text-left text-sm">
          <thead className="bg-sb-canvas text-[11px] uppercase tracking-wide text-sb-text-secondary"><tr><th className="px-5 py-3 font-semibold">Worker</th><th className="px-5 py-3 font-semibold">City</th><th className="px-5 py-3 font-semibold">Skills</th><th className="px-5 py-3 font-semibold">Track record</th><th className="px-5 py-3 font-semibold">Verification</th><th className="px-5 py-3 font-semibold">Joined</th><th className="px-5 py-3 text-right font-semibold">Action</th></tr></thead>
          <tbody className="divide-y divide-sb-border">
            {visibleWorkers.map((worker) => <tr key={worker.uid} className="hover:bg-sb-canvas/70">
              <td className="px-5 py-4"><div className="flex items-center gap-3"><Avatar className="h-9 w-9"><AvatarFallback className="bg-sb-primary-subtle text-xs font-semibold text-sb-primary">{worker.displayName.slice(0, 2).toUpperCase() || 'W'}</AvatarFallback></Avatar><div className="min-w-0"><p className="truncate font-semibold text-sb-text">{worker.displayName || 'Unnamed worker'}</p><p className="truncate text-xs text-sb-text-secondary">{worker.email || 'No email'}</p></div></div></td>
              <td className="px-5 py-4"><span className="inline-flex items-center gap-1.5 text-sb-text-secondary"><MapPin className="h-3.5 w-3.5 text-sb-text-secondary" />{worker.city || 'Not specified'}</span></td>
              <td className="max-w-56 px-5 py-4"><div className="flex flex-wrap gap-1">{worker.skills.slice(0, 3).map((skill) => <span key={skill} className="rounded-full bg-sb-primary-subtle px-2 py-0.5 text-[11px] text-sb-primary">{skill}</span>)}{worker.skills.length === 0 && <span className="text-xs text-sb-text-secondary">No skills listed</span>}</div></td>
              <td className="whitespace-nowrap px-5 py-4"><span className="inline-flex items-center gap-1 text-sb-on-warning-subtle"><Star className="h-3.5 w-3.5 fill-current" />{worker.rating.toFixed(1)}</span><span className="ml-2 text-xs text-sb-text-secondary">{worker.completedJobs} jobs</span></td>
              <td className="px-5 py-4"><span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${worker.isVerified ? 'bg-sb-success-subtle text-sb-on-success-subtle' : 'bg-sb-warning-subtle text-sb-on-warning-subtle'}`}>{worker.isVerified && <ShieldCheck className="h-3.5 w-3.5" />}{worker.isVerified ? 'Verified' : 'Pending'}</span></td>
              <td className="whitespace-nowrap px-5 py-4 text-xs text-sb-text-secondary">{worker.createdAt && !Number.isNaN(Date.parse(worker.createdAt)) ? new Date(worker.createdAt).toLocaleDateString() : '—'}</td>
              <td className="px-5 py-4 text-right">{canVerify ? <WorkerClientActions workerId={worker.uid} isVerified={worker.isVerified} /> : <span className="text-xs text-sb-text-secondary">Super admin only</span>}</td>
            </tr>)}
            {visibleWorkers.length === 0 && <tr><td colSpan={7} className="px-5 py-12 text-center text-sm text-sb-text-secondary">No workers match these filters.</td></tr>}
          </tbody>
        </table>
      </div>
      <div className="border-t border-sb-border px-5 py-3 text-xs text-sb-text-secondary">{visibleWorkers.length} matching workers</div>
    </section>
  );
}
