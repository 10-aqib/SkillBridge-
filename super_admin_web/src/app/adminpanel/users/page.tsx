import { UsersService } from '@/lib/services/users.service';
import { UsersTableClient } from './UsersTableClient';
import { Users, UserRound, Wrench } from 'lucide-react';

export const dynamic = 'force-dynamic';

export default async function UsersPage() {
  const users = await UsersService.getUsers(100);
  const clients = users.filter((user) => user.role === 'client').length;
  const workers = users.filter((user) => user.role === 'worker').length;
  const disabled = users.filter((user) => user.disabled).length;

  const metrics = [
    { label: 'Accounts loaded', value: users.length, icon: Users, tone: 'bg-sb-primary-subtle text-sb-primary' },
    { label: 'Clients', value: clients, icon: UserRound, tone: 'bg-sb-primary-subtle text-sb-on-primary-subtle' },
    { label: 'Workers', value: workers, icon: Wrench, tone: 'bg-sb-warning-subtle text-sb-on-warning-subtle' },
    { label: 'Disabled accounts', value: disabled, icon: Users, tone: 'bg-sb-error-subtle text-sb-error' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-sb-primary">Platform operations</p>
        <h1 className="mt-1 text-2xl font-bold tracking-tight text-sb-text sm:text-3xl">User directory</h1>
        <p className="mt-1 text-sm text-sb-text-secondary">Review Firebase accounts, access roles, and account availability.</p>
      </div>
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        {metrics.map(({ label, value, icon: Icon, tone }) => <article key={label} className="rounded-2xl border border-sb-border bg-sb-surface p-4 shadow-sm"><div className="flex items-center justify-between"><p className="text-sm text-sb-text-secondary">{label}</p><span className={`rounded-xl p-2 ${tone}`}><Icon className="h-4 w-4" /></span></div><p className="mt-3 text-2xl font-bold text-sb-text">{value}</p></article>)}
      </section>
      <UsersTableClient users={users} />
    </div>
  );
}
