import { UsersService } from '@/lib/services/users.service';
import { WorkersTableClient } from './WorkersTableClient';
import { BriefcaseBusiness, ShieldCheck, Clock3, UserRoundCheck } from 'lucide-react';
import { getAdminSession, isSuperAdmin } from '@/lib/auth/admin-session';

export const dynamic = 'force-dynamic';

export default async function WorkersPage() {
  const [workers, admin] = await Promise.all([UsersService.getWorkers(100), getAdminSession()]);
  const verified = workers.filter((worker) => worker.isVerified).length;
  const pending = workers.length - verified;
  const active = workers.filter((worker) => worker.isActive).length;
  const metrics = [
    { label: 'Profiles loaded', value: workers.length, icon: BriefcaseBusiness, tone: 'bg-sb-primary-subtle text-sb-primary' },
    { label: 'Verified', value: verified, icon: ShieldCheck, tone: 'bg-sb-success-subtle text-sb-on-success-subtle' },
    { label: 'Pending review', value: pending, icon: Clock3, tone: 'bg-sb-warning-subtle text-sb-on-warning-subtle' },
    { label: 'Active profiles', value: active, icon: UserRoundCheck, tone: 'bg-sb-primary-subtle text-sb-on-primary-subtle' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-sb-primary">Marketplace quality</p>
        <h1 className="mt-1 text-2xl font-bold tracking-tight text-sb-text sm:text-3xl">Worker verification</h1>
        <p className="mt-1 text-sm text-sb-text-secondary">Review real worker profiles and manage verification status.</p>
      </div>
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {metrics.map(({ label, value, icon: Icon, tone }) => <article key={label} className="rounded-2xl border border-sb-border bg-sb-surface p-4 shadow-sm"><div className="flex items-center justify-between"><p className="text-sm text-sb-text-secondary">{label}</p><span className={`rounded-xl p-2 ${tone}`}><Icon className="h-4 w-4" /></span></div><p className="mt-3 text-2xl font-bold text-sb-text">{value}</p></article>)}
      </section>
      <WorkersTableClient workers={workers} canVerify={admin ? isSuperAdmin(admin) : false} />
    </div>
  );
}
