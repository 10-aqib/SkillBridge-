import Link from 'next/link';
import { ArrowUpRight, ShieldAlert } from 'lucide-react';
import { ReportsService } from '@/lib/services/reports.service';

export async function ModerationSummary() {
  const queue = await ReportsService.getQueueSummary();
  return (
    <section className="rounded-2xl border border-sb-border bg-sb-surface p-5 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <span className="text-xs font-semibold uppercase tracking-wide text-sb-text-secondary">Trust & safety</span>
          <h2 className="mt-1 text-base font-bold text-sb-text">Report queue</h2>
          <p className="mt-1 text-xs text-sb-text-secondary">Live counts from Firestore</p>
        </div>
        <span className="rounded-xl bg-sb-primary-subtle p-2.5 text-sb-primary"><ShieldAlert className="h-5 w-5" /></span>
      </div>
      <div className="mt-5 grid grid-cols-2 gap-3">
        <div className="rounded-xl bg-sb-warning-subtle p-3"><p className="text-xs font-medium text-sb-on-warning-subtle">Open</p><p className="mt-1 text-2xl font-bold text-sb-on-warning-subtle">{queue.open}</p></div>
        <div className="rounded-xl bg-sb-primary-subtle p-3"><p className="text-xs font-medium text-sb-on-primary-subtle">Investigating</p><p className="mt-1 text-2xl font-bold text-sb-on-primary-subtle">{queue.investigating}</p></div>
      </div>
      <Link href="/adminpanel/reports" className="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-sb-primary hover:text-sb-primary-hover">
        Review reports <ArrowUpRight className="h-4 w-4" />
      </Link>
    </section>
  );
}
