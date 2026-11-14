'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Briefcase,
  ClipboardList,
  AlertTriangle,
  ShieldAlert,
  Settings,
  LogOut,
  Handshake,
  type LucideIcon,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { auth } from '@/lib/firebase/client';
import { signOut } from 'firebase/auth';
import type { AdminIdentity } from '@/lib/auth/admin-session';
import { ThemeToggle } from '@/components/sb/theme-toggle';

type NavRoute = { label: string; icon: LucideIcon; href: string };

// Same routes and labels as before, grouped by task.
const groups: { title?: string; routes: NavRoute[] }[] = [
  {
    routes: [{ label: 'Dashboard', icon: LayoutDashboard, href: '/adminpanel/dashboard' }],
  },
  {
    title: 'People',
    routes: [
      { label: 'Users', icon: Users, href: '/adminpanel/users' },
      { label: 'Workers', icon: Briefcase, href: '/adminpanel/workers' },
    ],
  },
  {
    title: 'Marketplace',
    routes: [
      { label: 'Jobs & Contracts', icon: ClipboardList, href: '/adminpanel/jobs' },
      { label: 'Reports & Disputes', icon: AlertTriangle, href: '/adminpanel/reports' },
    ],
  },
  {
    title: 'Governance',
    routes: [
      { label: 'Audit Logs', icon: ShieldAlert, href: '/adminpanel/audit-logs' },
      { label: 'Settings', icon: Settings, href: '/adminpanel/settings' },
    ],
  },
];

export function Sidebar({
  admin,
  onNavigate,
}: {
  admin: AdminIdentity;
  onNavigate?: () => void;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const displayName = admin.name || admin.email || 'Administrator';

  const handleLogout = async () => {
    try {
      await signOut(auth);
      await fetch('/api/auth/session', { method: 'DELETE' });
      router.push('/admin-login');
      router.refresh();
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  return (
    <aside
      data-sb
      aria-label="Admin navigation"
      className="flex h-full w-64 select-none flex-col border-r border-sb-border bg-sb-surface"
    >
      {/* Brand */}
      <div className="flex h-16 items-center gap-2.5 border-b border-sb-border px-5">
        <span className="flex size-8 items-center justify-center rounded-sb-control bg-sb-primary text-sb-on-primary">
          <Handshake aria-hidden className="size-[18px]" />
        </span>
        <span className="flex flex-col leading-tight">
          <span className="text-sm font-bold text-sb-text">SkillBridge</span>
          <span className="text-xs text-sb-text-secondary">Admin console</span>
        </span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto px-3 py-3">
        {groups.map((group, gi) => (
          <div key={group.title ?? gi} className={cn(gi > 0 && 'mt-4')}>
            {group.title && (
              <p className="px-3 pb-1.5 text-[11px] font-semibold uppercase tracking-wider text-sb-text-secondary">
                {group.title}
              </p>
            )}
            <ul className="space-y-0.5">
              {group.routes.map((route) => {
                const isActive = pathname === route.href || pathname.startsWith(`${route.href}/`);
                const Icon = route.icon;
                return (
                  <li key={route.href}>
                    <Link
                      href={route.href}
                      onClick={onNavigate}
                      aria-current={isActive ? 'page' : undefined}
                      className={cn(
                        'sb-focus flex h-10 items-center gap-3 rounded-sb-control px-3 text-sm transition-colors duration-150',
                        isActive
                          ? 'bg-sb-primary-subtle font-semibold text-sb-on-primary-subtle'
                          : 'font-medium text-sb-text-secondary hover:bg-sb-canvas hover:text-sb-text',
                      )}
                    >
                      <Icon aria-hidden className="size-[18px] shrink-0" />
                      <span className="truncate">{route.label}</span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </nav>

      {/* Theme switch lives in the header from 640px up; the drawer carries it on phones. */}
      <div className="flex items-center justify-between border-t border-sb-border px-5 py-2.5 sm:hidden">
        <span className="text-xs font-medium text-sb-text-secondary">Theme</span>
        <ThemeToggle />
      </div>

      {/* Identity + sign out */}
      <div className="flex items-center gap-3 border-t border-sb-border px-4 py-3">
        <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-sb-primary-subtle text-xs font-semibold text-sb-on-primary-subtle">
          {displayName.slice(0, 2).toUpperCase()}
        </span>
        <span className="flex min-w-0 flex-1 flex-col leading-tight">
          <span className="truncate text-sm font-semibold text-sb-text">{displayName}</span>
          <span className="text-xs text-sb-text-secondary">
            {admin.role === 'admin' ? 'Administrator' : 'Super Administrator'}
          </span>
        </span>
        <button
          type="button"
          onClick={handleLogout}
          aria-label="Sign out"
          title="Sign out"
          className="sb-focus flex size-9 items-center justify-center rounded-sb-control text-sb-text-secondary transition-colors hover:bg-sb-error-subtle hover:text-sb-error"
        >
          <LogOut aria-hidden className="size-[18px] rtl:rotate-180" />
        </button>
      </div>
    </aside>
  );
}
