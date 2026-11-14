'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { Search, UserRound, UserX } from 'lucide-react';

export interface AdminUserRow {
  uid: string;
  email: string;
  displayName: string;
  role: string;
  disabled: boolean;
  isActive: boolean;
  createdAt: string;
}

export function UsersTableClient({ users }: { users: AdminUserRow[] }) {
  const [query, setQuery] = useState('');
  const [role, setRole] = useState('all');
  const [status, setStatus] = useState('all');
  const visibleUsers = useMemo(() => users.filter((user) => {
    const normalizedQuery = query.trim().toLowerCase();
    const matchesQuery = !normalizedQuery || [user.displayName, user.email, user.uid, user.role]
      .some((value) => value.toLowerCase().includes(normalizedQuery));
    return matchesQuery && (role === 'all' || user.role === role) &&
      (status === 'all' || (status === 'active' ? !user.disabled : user.disabled));
  }), [users, query, role, status]);

  return (
    <section className="overflow-hidden rounded-2xl border border-sb-border bg-sb-surface shadow-sm">
      <div className="flex flex-col gap-3 border-b border-sb-border p-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h2 className="font-semibold text-sb-text">Accounts</h2>
          <p className="mt-0.5 text-xs text-sb-text-secondary">Showing the latest {users.length} Firebase Authentication accounts.</p>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <label className="relative sm:w-64">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-sb-text-secondary" />
            <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search name, email, ID" className="h-10 w-full rounded-xl border border-sb-border pl-9 pr-3 text-sm outline-none focus:border-sb-focus focus:ring-2 focus:ring-sb-focus/20" />
          </label>
          <select value={role} onChange={(event) => setRole(event.target.value)} aria-label="Filter users by role" className="h-10 rounded-xl border border-sb-border bg-sb-surface px-3 text-sm outline-none focus:border-sb-focus">
            <option value="all">All roles</option><option value="client">Clients</option><option value="worker">Workers</option><option value="admin">Admins</option><option value="SUPER_ADMIN">Super admins</option><option value="unassigned">Unassigned</option>
          </select>
          <select value={status} onChange={(event) => setStatus(event.target.value)} aria-label="Filter users by account status" className="h-10 rounded-xl border border-sb-border bg-sb-surface px-3 text-sm outline-none focus:border-sb-focus">
            <option value="all">All account states</option><option value="active">Enabled</option><option value="disabled">Disabled</option>
          </select>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[760px] text-left text-sm">
          <thead className="bg-sb-canvas text-[11px] uppercase tracking-wide text-sb-text-secondary"><tr>
            <th className="px-5 py-3 font-semibold">Account</th><th className="px-5 py-3 font-semibold">Role</th><th className="px-5 py-3 font-semibold">Auth status</th><th className="px-5 py-3 font-semibold">Joined</th><th className="px-5 py-3 text-right font-semibold">Profile</th>
          </tr></thead>
          <tbody className="divide-y divide-sb-border">
            {visibleUsers.map((user) => (
              <tr key={user.uid} className="hover:bg-sb-canvas/70">
                <td className="px-5 py-4"><div className="flex items-center gap-3"><span className="flex h-9 w-9 items-center justify-center rounded-full bg-sb-primary-subtle text-sb-primary"><UserRound className="h-4 w-4" /></span><div className="min-w-0"><p className="truncate font-semibold text-sb-text">{user.displayName || 'Unnamed account'}</p><p className="truncate text-xs text-sb-text-secondary">{user.email || 'No email'}</p></div></div></td>
                <td className="px-5 py-4"><span className="rounded-full bg-sb-primary-subtle px-2.5 py-1 text-xs font-medium capitalize text-sb-primary">{user.role.replaceAll('_', ' ')}</span></td>
                <td className="px-5 py-4"><span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-xs font-medium ${user.disabled ? 'bg-sb-error-subtle text-sb-error' : 'bg-sb-success-subtle text-sb-on-success-subtle'}`}>{user.disabled && <UserX className="h-3.5 w-3.5" />}{user.disabled ? 'Disabled' : 'Enabled'}</span></td>
                <td className="whitespace-nowrap px-5 py-4 text-xs text-sb-text-secondary">{user.createdAt && !Number.isNaN(Date.parse(user.createdAt)) ? new Date(user.createdAt).toLocaleDateString() : '—'}</td>
                <td className="px-5 py-4 text-right"><Link href={`/adminpanel/users/${encodeURIComponent(user.uid)}`} className="rounded-lg border border-sb-border px-3 py-1.5 text-xs font-semibold text-sb-text-secondary hover:bg-sb-canvas">View account</Link></td>
              </tr>
            ))}
            {visibleUsers.length === 0 && <tr><td colSpan={5} className="px-5 py-12 text-center text-sm text-sb-text-secondary">No accounts match these filters.</td></tr>}
          </tbody>
        </table>
      </div>
      <div className="border-t border-sb-border px-5 py-3 text-xs text-sb-text-secondary">{visibleUsers.length} matching accounts</div>
    </section>
  );
}
